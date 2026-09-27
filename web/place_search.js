// ============================================================
// ResQNav — Places Autocomplete + Routing
// ============================================================

// ─── 1. PLACES AUTOCOMPLETE ──────────────────────────────────

window.initResQNavPlaces = async function (containerId, callback) {
  try {
    const container = document.getElementById(containerId);

    if (!container) {
      console.error('ResQNav: Search container not found:', containerId);
      return;
    }

    const { PlaceAutocompleteElement } = await google.maps.importLibrary('places');

    container.innerHTML = '';

    const placeAutocomplete = new PlaceAutocompleteElement();
    placeAutocomplete.includedRegionCodes = ['in'];
    placeAutocomplete.placeholder        = 'Search any destination...';
    placeAutocomplete.style.width        = '100%';
    placeAutocomplete.style.height       = '100%';

    container.appendChild(placeAutocomplete);

    placeAutocomplete.addEventListener('gmp-error', (event) => {
      console.error('ResQNav Places API error:', event);
    });

    placeAutocomplete.addEventListener('gmp-select', async ({ placePrediction }) => {
      try {
        const place = placePrediction.toPlace();

        await place.fetchFields({
          fields: ['displayName', 'formattedAddress', 'location'],
        });

        if (!place.location) {
          console.error('ResQNav: Selected place has no location.');
          return;
        }

        callback(
          place.displayName      || '',
          place.formattedAddress || '',
          place.location.lat(),
          place.location.lng(),
        );
      } catch (error) {
        console.error('ResQNav: Place details error:', error);
      }
    });

    console.log('ResQNav Places Autocomplete initialised in:', containerId);
  } catch (error) {
    console.error('ResQNav Places initialisation error:', error);
  }
};

// ─── 2. ROUTING (OSRM with two fallback servers) ─────────────

// Primary and fallback OSRM-compatible endpoints
const OSRM_SERVERS = {
  car:  [
    'https://router.project-osrm.org/route/v1',
    'https://routing.openstreetmap.de/routed-car/route/v1',
  ],
  walk: [
    'https://router.project-osrm.org/route/v1',
    'https://routing.openstreetmap.de/routed-foot/route/v1',
  ],
};

async function fetchOSRMRoute(baseUrl, profile, originLng, originLat, destLng, destLat) {
  const url =
    `${baseUrl}/${profile}/` +
    `${Number(originLng)},${Number(originLat)};` +
    `${Number(destLng)},${Number(destLat)}` +
    `?overview=full&geometries=geojson&steps=false`;

  const response = await fetch(url, { method: 'GET', cache: 'no-store' });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status} from ${baseUrl}`);
  }

  const data = await response.json();

  if (data.code !== 'Ok' || !data.routes || data.routes.length === 0) {
    throw new Error(data.message || `No route (code: ${data.code})`);
  }

  return data.routes[0];
}

window.computeResQNavRoute = async function (
  originLat, originLng,
  destinationLat, destinationLng,
  travelMode,
  callback,
) {
  const mode    = String(travelMode);
  const profile = mode === 'walk' ? 'foot' : 'driving';
  const servers = mode === 'walk' ? OSRM_SERVERS.walk : OSRM_SERVERS.car;

  console.group('ResQNav Routing');
  console.log('Mode:', mode, '| Profile:', profile);
  console.log('Origin:', originLat, originLng);
  console.log('Destination:', destinationLat, destinationLng);

  let lastError = null;

  for (const serverBase of servers) {
    try {
      console.log('Trying server:', serverBase);

      const route = await fetchOSRMRoute(
        serverBase, profile,
        Number(originLng), Number(originLat),
        Number(destinationLng), Number(destinationLat),
      );

      const coordinates = route.geometry?.coordinates || [];

      if (coordinates.length === 0) {
        throw new Error('Empty coordinate array from server.');
      }

      const pathData = coordinates.map((pt) => ({
        lat: Number(pt[1]),
        lng: Number(pt[0]),
      }));

      const distance = Number(route.distance || 0);       // metres
      const duration = Number(route.duration || 0) * 1000; // convert s → ms

      console.log('✓ Route found via:', serverBase);
      console.log('  Distance:', distance, 'm | Duration:', duration, 'ms | Points:', pathData.length);
      console.groupEnd();

      callback(JSON.stringify(pathData), distance, duration);
      return;

    } catch (err) {
      console.warn('Server failed:', serverBase, '—', err.message);
      lastError = err;
    }
  }

  // All servers failed — try a straight-line fallback with Haversine distance
  console.warn('All OSRM servers failed. Using straight-line fallback.');
  console.groupEnd();

  try {
    const straightLine = buildStraightLineRoute(
      Number(originLat), Number(originLng),
      Number(destinationLat), Number(destinationLng),
    );

    callback(
      JSON.stringify(straightLine.points),
      straightLine.distance,
      straightLine.duration,
    );
  } catch (fallbackErr) {
    console.error('ResQNav Routing: straight-line fallback also failed:', fallbackErr);
    callback(JSON.stringify([]), 0, 0);
  }
};

// ─── Straight-line route fallback ────────────────────────────

function buildStraightLineRoute(lat1, lng1, lat2, lng2) {
  const R        = 6371000; // Earth radius metres
  const toRad    = (d) => (d * Math.PI) / 180;
  const dLat     = toRad(lat2 - lat1);
  const dLng     = toRad(lng2 - lng1);
  const a        = Math.sin(dLat / 2) ** 2 +
                   Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
                   Math.sin(dLng / 2) ** 2;
  const distance = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  // Walking speed ~1.4 m/s → convert to ms
  const duration = (distance / 1.4) * 1000;

  // Build a simple 2-point polyline
  const points = [
    { lat: lat1, lng: lng1 },
    { lat: lat2, lng: lng2 },
  ];

  return { points, distance, duration };
}

// ─── 3. GEOCODING HELPER (used by History "View Again") ──────

/**
 * Reverse-geocode a lat/lng using the Google Maps Geocoding API.
 * Returns a human-readable address string, or an empty string on failure.
 */
window.resqnavReverseGeocode = async function (lat, lng) {
  try {
    const { Geocoder } = await google.maps.importLibrary('geocoding');
    const geocoder     = new Geocoder();

    const result = await geocoder.geocode({ location: { lat: Number(lat), lng: Number(lng) } });

    if (result.results && result.results.length > 0) {
      return result.results[0].formatted_address || '';
    }

    return '';
  } catch (err) {
    console.warn('ResQNav reverse-geocode error:', err);
    return '';
  }
};

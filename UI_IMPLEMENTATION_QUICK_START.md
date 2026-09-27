# 🚀 UI Implementation Quick Start

**Get Started with Premium UI in 5 Minutes**

---

## Step 1: Update main.dart

Replace your existing theme with the premium theme:

```dart
import 'package:flutter/material.dart';
import 'core/theme/premium_theme.dart';

void main() {
  runApp(const ResQNavApp());
}

class ResQNavApp extends StatelessWidget {
  const ResQNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQNav - Emergency Response',
      debugShowCheckedModeBanner: false,
      theme: PremiumTheme.lightTheme,  // ← Use premium theme
      home: const HomePage(),
    );
  }
}
```

---

## Step 2: Import Premium Widgets

In any screen where you want to use premium components:

```dart
import 'package:resqnav/core/widgets/premium_widgets.dart';
import 'package:resqnav/core/theme/premium_theme.dart';
```

---

## Step 3: Example - Home Screen with Premium Design

```dart
import 'package:flutter/material.dart';
import 'package:resqnav/core/widgets/premium_widgets.dart';
import 'package:resqnav/core/theme/premium_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            PremiumHeader(
              title: 'Emergency Response',
              subtitle: 'Fast access to emergency services',
            ),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert Box
                    PremiumAlert(
                      title: 'Pro Tip',
                      message: 'Keep emergency contacts updated for faster response',
                      type: AlertType.info,
                    ),
                    const SizedBox(height: 24),
                    
                    // Services Section
                    Text(
                      'Nearby Services',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    
                    // Service Cards
                    PremiumCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => print('Tapped Hospital'),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: PremiumTheme.premiumGradient,
                              borderRadius: BorderRadius.circular(
                                PremiumTheme.radiusMD,
                              ),
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'St. Mary Hospital',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Open 24/7 • 2.3 km away',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        PremiumChip(
                          label: 'Hospitals',
                          icon: Icons.local_hospital,
                          isSelected: true,
                        ),
                        PremiumChip(
                          label: 'Police',
                          icon: Icons.shield,
                        ),
                        PremiumChip(
                          label: 'Fire Station',
                          icon: Icons.fire_truck,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // SOS Button with Premium styling
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSOSDialog(context),
        backgroundColor: PremiumTheme.danger,
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text(
          'SOS EMERGENCY',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Emergency Alert'),
        content: const Text(
          'This will send alerts to your emergency contacts with your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PremiumButton(
            label: 'Send Alert',
            onPressed: () {
              Navigator.pop(context);
              print('SOS Alert Sent!');
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Step 4: Example - Login Screen

```dart
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Logo/Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: PremiumTheme.premiumGradient,
                  borderRadius: BorderRadius.circular(
                    PremiumTheme.radiusXL,
                  ),
                ),
                child: const Icon(
                  Icons.emergency,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to access emergency services',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: PremiumTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Email Input
              PremiumInput(
                label: 'Email Address',
                hint: 'you@example.com',
                controller: emailController,
                prefixIcon: Icons.email_outlined,
              ),
              
              const SizedBox(height: 20),
              
              // Password Input
              PremiumInput(
                label: 'Password',
                hint: 'Enter your password',
                controller: passwordController,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              
              const SizedBox(height: 24),
              
              // Remember & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: false,
                        onChanged: (value) {},
                      ),
                      Text(
                        'Remember me',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                child: PremiumButton(
                  label: 'Sign In',
                  isLoading: isLoading,
                  onPressed: () async {
                    setState(() => isLoading = true);
                    await Future.delayed(
                      const Duration(seconds: 2),
                    );
                    setState(() => isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Login successful!'),
                        ),
                      );
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: PremiumTheme.divider,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: PremiumTheme.divider,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Google Sign-In Button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: PremiumTheme.border,
                  ),
                  borderRadius: BorderRadius.circular(
                    PremiumTheme.radiusMD,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(
                      PremiumTheme.radiusMD,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google_logo.png',
                            width: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sign in with Google',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Sign up',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PremiumTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
```

---

## Step 5: Example - Services List Screen

```dart
class ExploreServicesPage extends StatefulWidget {
  const ExploreServicesPage({super.key});

  @override
  State<ExploreServicesPage> createState() => _ExploreServicesPageState();
}

class _ExploreServicesPageState extends State<ExploreServicesPage> {
  String selectedCategory = 'Hospital';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            PremiumHeader(
              title: 'Services',
              subtitle: 'Find nearby emergency services',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Filter
                    Text(
                      'Service Categories',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Hospital',
                          'Police',
                          'Fire',
                          'Ambulance',
                          'Pharmacy',
                        ]
                            .map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: PremiumChip(
                                  label: category,
                                  isSelected:
                                      selectedCategory == category,
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = category;
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Services List
                    Text(
                      'Available Services',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    
                    // Service Item 1
                    PremiumCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: PremiumTheme.primarySuper,
                                  borderRadius: BorderRadius.circular(
                                    PremiumTheme.radiusMD,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.local_hospital,
                                  color: PremiumTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'City General Hospital',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '45 Medical Plaza',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: PremiumTheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '2.5 km away',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: PremiumTheme.successGradient
                                      .colors[0]
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    PremiumTheme.radiusSM,
                                  ),
                                ),
                                child: Text(
                                  'Open 24/7',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: PremiumTheme.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: PremiumButton(
                              label: 'Get Directions',
                              onPressed: () {},
                              icon: Icons.navigation,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## File Structure After Implementation

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart (original)
│   │   └── premium_theme.dart ← NEW
│   └── widgets/
│       ├── common_widgets.dart
│       └── premium_widgets.dart ← NEW
│
├── features/
│   ├── auth/
│   │   └── login_page.dart (UPDATE with premium widgets)
│   ├── home/
│   │   └── home_page.dart (UPDATE with premium widgets)
│   ├── explore/
│   │   └── explore_page.dart (UPDATE with premium widgets)
│   └── ...
│
├── main.dart (UPDATE theme to PremiumTheme)
└── ...
```

---

## Next Steps

1. **Replace Theme**: Update `main.dart` to use `PremiumTheme`
2. **Update Screens**: Gradually migrate screens to use `PremiumButton`, `PremiumCard`, etc.
3. **Test**: Verify on multiple devices
4. **Optimize**: Profile and optimize performance
5. **Deploy**: Push to production with new UI

---

## Tips for Success

✅ Start with one screen at a time  
✅ Test on real devices  
✅ Use the DevTools to profile  
✅ Keep animations smooth  
✅ Maintain accessibility  
✅ Get user feedback early  
✅ Iterate based on feedback  

---

**Happy Designing! 🎨**

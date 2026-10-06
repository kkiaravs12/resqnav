allprojects {
    repositories {
        // Use HTTP mirror for google repository
        maven {
            url = uri("https://maven.google.com/")
            isAllowInsecureProtocol = true
        }
        google()
        mavenCentral()
        maven { url = uri("https://jcenter.bintray.com/") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

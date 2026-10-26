allprojects { repositories { google(); mavenCentral() } }
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    layout.buildDirectory.value(newBuildDir.dir(project.name))
    // Use Flutter's NDK for native plugins as well as the application.
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            ndkVersion = "28.2.13676358"
        }
    }
    evaluationDependsOn(":app")
}
tasks.register<Delete>("clean") { delete(rootProject.layout.buildDirectory) }

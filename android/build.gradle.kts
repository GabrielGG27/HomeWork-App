plugins {
    // Agrega esta línea para declarar el plugin de Google Services sin aplicarlo aún
    id("com.google.gms.google-services") version "4.4.4" apply false
    id("com.google.firebase.crashlytics") version "3.0.7" apply false
}



val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // google_mobile_ads 9.0.0 ships native-ad layouts that reference
    // AppCompatButton without declaring AppCompat in its Android module.
    // Add the missing runtime dependency to that module only.
    if (project.name == "google_mobile_ads") {
        project.pluginManager.withPlugin("com.android.library") {
            project.dependencies.add(
                "implementation",
                "androidx.appcompat:appcompat:1.7.1",
            )
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

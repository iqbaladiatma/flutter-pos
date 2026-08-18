allprojects {
    repositories {
        google()
        mavenCentral()
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

// Fix for discontinued plugins that don't specify a namespace (AGP 8+ requirement).
subprojects {
    project.plugins.withId("com.android.library") {
        val androidExtension = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (androidExtension.namespace.isNullOrEmpty()) {
            val pkg = project.group.toString()
            if (pkg.isNotEmpty() && pkg != "unspecified") {
                androidExtension.namespace = pkg
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

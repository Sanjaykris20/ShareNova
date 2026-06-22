buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    layout.buildDirectory.set(newSubprojectBuildDir)
    evaluationDependsOn(":app")

    if (project.path != ":app") {
        afterEvaluate {
            val android = extensions.findByName("android")
            if (android != null && android is com.android.build.gradle.BaseExtension) {
                if (android.namespace == null) {
                    val namespaceName = project.group.toString().let {
                        if (it.isEmpty()) "com.example.${project.name.replace("-", "_").replace(" ", "_")}" else it
                    }
                    android.namespace = namespaceName
                }
            }
        }
    }
}
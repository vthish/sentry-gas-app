// --- android/build.gradle.kts (FINAL UPDATED) ---
// This file is the Project-level build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        // Android Gradle Plugin
        classpath("com.android.tools.build:gradle:8.6.0") // Or your current version
        
        // [IMPORTANT]: Version updated to 2.1.4 as required by the build error
        classpath("com.android.tools:desugar_jdk_libs:2.1.4")
        
        // Kotlin plugin classpath
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0") // Or your current version
    }
}

allprojects {
     repositories {
         google()
         mavenCentral()
     }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
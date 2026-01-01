// ✅ 1. ADD THIS BUILDSCRIPT BLOCK AT THE VERY TOP
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // This must be inside 'buildscript' -> 'dependencies'
        // Note the Kotlin syntax: parentheses () and double quotes ""
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// ✅ 2. KEEP ALLPROJECTS (But do not put dependencies here)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ 3. THE REST OF YOUR FILE (Standard Flutter/Kotlin setup)
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
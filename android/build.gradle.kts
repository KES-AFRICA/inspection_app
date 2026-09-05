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

subprojects {
    val configureLibrary = {
        if (plugins.hasPlugin("com.android.library")) {
            val android = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
            if (project.name.contains("pdf_merger")) {
                android.compileSdk = 34
                android.namespace = "com.ril.pdf_merger"
            } else {
                android.compileSdk = 36
                if (android.namespace == null) {
                    android.namespace = "com.aup.${project.name.replace("-", "_").replace(".", "_")}"
                }
            }
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val content = manifestFile.readText()
                if (content.contains("package=")) {
                    val cleaned = content.replace(Regex("""\s*package="[^"]+""""), "")
                    manifestFile.writeText(cleaned)
                }
            }
        }
    }
    if (state.executed) {
        configureLibrary()
    } else {
        afterEvaluate { configureLibrary() }
    }

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

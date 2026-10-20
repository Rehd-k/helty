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

// file_picker 11+ skips the Kotlin plugin on AGP 9 and expects built-in Kotlin.
// This app still uses android.builtInKotlin=false, so FilePickerPlugin is never compiled.
subprojects {
    if (name != "file_picker") return@subprojects
    pluginManager.apply("org.jetbrains.kotlin.android")
    afterEvaluate {
        val plugin = plugins.first {
            it.javaClass.name.contains("KotlinAndroidPlugin")
        }
        val kotlinExt = extensions.getByName("kotlin")
        val compilerOptions = kotlinExt.javaClass
            .getMethod("getCompilerOptions")
            .invoke(kotlinExt)
        val jvmTarget = compilerOptions.javaClass
            .getMethod("getJvmTarget")
            .invoke(compilerOptions)
        val jvm17 = Class.forName(
            "org.jetbrains.kotlin.gradle.dsl.JvmTarget",
            true,
            plugin.javaClass.classLoader,
        ).enumConstants.first { it.toString() == "JVM_17" }
        // Property.set(T) erases to set(Object). set(Provider) is the other
        // one-arg overload and throws argument type mismatch for a JvmTarget.
        jvmTarget.javaClass.methods
            .single {
                it.name == "set" &&
                    it.parameterCount == 1 &&
                    it.parameterTypes[0] == Any::class.java
            }
            .invoke(jvmTarget, jvm17)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

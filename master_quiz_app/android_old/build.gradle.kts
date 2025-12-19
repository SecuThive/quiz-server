allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 빌드 파일 저장 위치 설정 (건드리지 마세요!)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// 청소(Clean) 작업 정의
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
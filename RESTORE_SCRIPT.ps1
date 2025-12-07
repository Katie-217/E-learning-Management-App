# RESTORE SCRIPT - Generated on 2025-12-07
# Run this to restore all backed up files

$backupDir = "d:\TDT_lesson\CrossPlatform\Final\E-learning-Management-App\FULL_BACKUP_2025-12-07_00-27-44"
$projectRoot = "d:\TDT_lesson\CrossPlatform\Final\E-learning-Management-App"

$files = @(
"functions/src/index.ts",
"lib/data/repositories/quiz/quiz_repository.dart",
"lib/data/repositories/notification/notification_repository.dart",
"lib/domain/models/quiz_model.dart",
"lib/domain/models/question_model.dart",
"lib/presentation/screens/instructor/classwork_tab/quiz/question_bank_page.dart",
"lib/presentation/screens/instructor/classwork_tab/quiz/question_editor_page.dart",
"lib/presentation/widgets/course/instructor_course_grade/instructor_grade_tab_v2.dart",
"lib/presentation/widgets/course/instructor_course_grade/grade_filter_bar.dart",
"lib/presentation/widgets/course/instructor_course_grade/gradebook_table_v2.dart",
"lib/presentation/widgets/course/instructor_course_grade/quiz_gradebook_table.dart",
"lib/presentation/widgets/course/instructor_course_grade/gradebook_export_v2.dart",
"lib/presentation/widgets/common/main_shell.dart",
"lib/presentation/widgets/course/Instructor_Course/widget_course/instructor_course_tabs_widget.dart",
"lib/presentation/widgets/student/course/assignment/assignment_card.dart",
"lib/presentation/widgets/student/dashboard/app_bar/student_dashboard_app_bar.dart",
"lib/presentation/widgets/student/dashboard/app_bar/notification/notification_menu.dart",
"lib/presentation/widgets/student/dashboard/app_bar/notification/notification_detail_dialog.dart"
)

$restored = 0
foreach ($file in $files) {
    $source = Join-Path $backupDir $file
    $target = Join-Path $projectRoot $file
    if (Test-Path $source) {
        Copy-Item $source $target -Force
        $restored++
        Write-Host " Restored: $file"
    } else {
        Write-Host " Not found: $file"
    }
}

Write-Host "`n Restored $restored files successfully!"

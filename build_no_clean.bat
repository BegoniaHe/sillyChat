@echo off
setlocal

:: �������Ŀ¼����
set OUTPUT_DIR=build_output

:: ��ȡ�ű�����Ŀ¼����Ϊ��Ŀ��Ŀ¼
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo.
echo ===========================================
echo   Flutter һ�������ű�
echo   Ŀ��: Android APK Windows EXE
echo ===========================================
echo.

:: 2. �������Ŀ¼
echo --- �������Ŀ¼: %OUTPUT_DIR% ---
if exist "%OUTPUT_DIR%" (
    rmdir /s /q "%OUTPUT_DIR%"
)
mkdir "%OUTPUT_DIR%"
if %ERRORLEVEL% NEQ 0 (
    echo ����: �޷��������Ŀ¼��
    pause
    exit /b %ERRORLEVEL%
)
echo.

:: 3. ���� Android APK (Release)
echo --- ���� Android APK (Release) ---
flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo ����: Android APK ����ʧ�ܡ�
    echo ��ȷ������ Android SDK �� Gradle ������ȷ��
    pause
    exit /b %ERRORLEVEL%
)
echo.

:: 4. ���� Android APK �����Ŀ¼
echo --- ���� Android APK �� %OUTPUT_DIR% ---
xcopy /y "build\app\outputs\flutter-apk\app-release.apk" "%OUTPUT_DIR%\"
if %ERRORLEVEL% NEQ 0 (
    echo ����: �޷����� Android APK������δ�ҵ��ļ���
)
echo.

:: 5. ���� Windows EXE (Release)
echo --- ���� Windows EXE (Release) ---
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo ����: Windows EXE ����ʧ�ܡ�
    echo ��ȷ�����Ѱ�װ C++ ���濪���������� (Visual Studio)��
    pause
    exit /b %ERRORLEVEL%
)
echo.

:: 6. ���� Windows �������ﵽ���Ŀ¼
echo --- ���� Windows �������ﵽ %OUTPUT_DIR% ---
:: Windows �����Ὣ�����ļ����� build\windows\x64\runner\Release Ŀ¼��
xcopy /e /i /y "build\windows\x64\runner\Release" "%OUTPUT_DIR%\Windows_App"
if %ERRORLEVEL% NEQ 0 (
    echo ����: �޷����� Windows �����������δ�ҵ��ļ���
)
echo.

echo ===========================================
echo   ������ɣ�
echo   ���й��������ѱ��浽: %OUTPUT_DIR%
echo ===========================================
echo.

pause
endlocal
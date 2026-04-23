Để build dự án Flutter của bạn thành file **APK** (Android Package) để cài đặt thử nghiệm trên điện thoại hoặc gửi cho bạn bè, bạn cần thực hiện theo các bước chuẩn hóa sau.

### 1\. Chuẩn bị trước khi Build (Pre-build)

Trước khi tạo APK, bạn cần kiểm tra và cấu hình một số thông tin cơ bản trong project:

*   **Đổi tên Package (Bundle ID):** Vào file android/app/build.gradle, tìm dòng applicationId. Hãy đổi nó thành định dạng như com.yourname.mysterywar (tránh để mặc định là com.example... vì Google Play sẽ không chấp nhận).
    
*   **Cấu hình Icon:** Sử dụng package flutter\_launcher\_icons để tự động gen icon cho các kích thước màn hình Android.
    
*   XML
    

### 2\. Các loại File APK

Bạn có 2 lựa chọn chính khi build:

*   **Debug APK:** Dùng để test nhanh, dung lượng nặng, hiệu năng không tối ưu.
    
*   **Release APK:** Đã được tối ưu hóa, dung lượng nhẹ, chạy mượt nhưng cần được ký tên (Sign).
    

### 3\. Hướng dẫn Build Release APK (Từng bước)

#### Bước 3.1: Tạo KeyStore (Ký tên ứng dụng)

Android yêu cầu mọi app Release phải được ký bằng một chứng chỉ số.

1.  Bashkeytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    
2.  Làm theo hướng dẫn để nhập mật khẩu (Hãy nhớ kỹ mật khẩu này).
    

#### Bước 3.2: Cấu hình file key.properties

Tạo một file tên key.properties trong thư mục android/ và điền thông tin:

Properties

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   storePassword=mật_khẩu_của_bạn  keyPassword=mật_khẩu_của_bạn  keyAlias=upload  storeFile=/đường/dẫn/đến/file/upload-keystore.jks   `

#### Bước 3.3: Chỉnh sửa android/app/build.gradle

Cập nhật khối signingConfigs để Flutter biết cách sử dụng key bạn vừa tạo. (Bạn có thể nhờ **DeepSeek** viết chính xác đoạn code này cho file build.gradle của bạn).

#### Bước 3.4: Lệnh Build

Mở Terminal tại thư mục gốc của project và chạy:

Bash

Plain textANTLR4BashCC#CSSCoffeeScriptCMakeDartDjangoDockerEJSErlangGitGoGraphQLGroovyHTMLJavaJavaScriptJSONJSXKotlinLaTeXLessLuaMakefileMarkdownMATLABMarkupObjective-CPerlPHPPowerShell.propertiesProtocol BuffersPythonRRubySass (Sass)Sass (Scss)SchemeSQLShellSwiftSVGTSXTypeScriptWebAssemblyYAMLXML`   # Build 1 file APK duy nhất cho mọi kiến trúc chíp (Dễ dùng nhưng file nặng)  flutter build apk --release  # HOẶC Build chia nhỏ theo kiến trúc (Tối ưu dung lượng cho từng máy)  flutter build apk --split-per-abi   `

### 4\. Lấy file APK ở đâu?

Sau khi lệnh chạy xong, bạn sẽ thấy đường dẫn hiện ra trong Terminal. Thông thường file sẽ nằm tại:\[Thư\_mục\_project\]/build/app/outputs/flutter-apk/app-release.apk

### 💡 Lưu ý quan trọng cho "Mystery War":

1.  **Firebase & APK:** Khi bạn build APK, bạn phải đảm bảo đã thêm **SHA-1 fingerprint** của file KeyStore bạn vừa tạo vào phần cài đặt project trên **Firebase Console**. Nếu không, tính năng gọi Cloud Functions (DeepSeek) sẽ bị từ chối trên bản Release.
    
2.  **Kích thước file:** Cờ vua là game nhẹ, nếu file APK của bạn trên 50MB, hãy kiểm tra lại các file nhạc nền .mp3. Nên dùng định dạng .ogg hoặc giảm bitrate nhạc xuống để tối ưu dung lượng.
    
3.  **App Bundle (.aab):** Nếu bạn định up lên Google Play thay vì cài trực tiếp, hãy dùng lệnh flutter build appbundle. Google hiện nay ưu tiên định dạng này hơn APK
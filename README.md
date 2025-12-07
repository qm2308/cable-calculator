# Cordova打包方案 - 跨平台移动应用

## 方案概述

使用Apache Cordova将HTML应用打包为真正的原生移动应用，支持Android和iOS平台，同时兼容鸿蒙系统的WebView内核。

## 技术优势

- 📱 **跨平台**: 一套代码支持Android、iOS、鸿蒙等多个平台
- 🔧 **原生插件**: 可调用设备原生API和功能
- 🛠️ **工具链成熟**: 丰富的插件生态和开发工具
- 📦 **应用商店**: 支持发布到各大应用商店

## 环境准备

### 1. 安装Node.js和npm
```bash
# 检查Node.js版本
node --version
npm --version

# 安装最新版本（如果需要）
npm install -g n
sudo n stable
```

### 2. 安装Cordova CLI
```bash
npm install -g cordova
cordova --version
```

### 3. 安装平台SDK
```bash
# Android SDK (推荐使用Android Studio)
# iOS SDK (需要Xcode，macOS系统)
# 鸿蒙SDK (从华为开发者平台下载)
```

## 项目创建

### 1. 初始化Cordova项目
```bash
# 创建新项目
cordova create cable-calculator com.hongteng.cablecalculator "红腾电气电缆计算器"

cd cable-calculator

# 添加平台支持
cordova platform add android
cordova platform add ios
cordova platform add harmonyos  # 如果支持的话

# 查看已安装的平台
cordova platform list
```

### 2. 项目结构
```
cable-calculator/
├── config.xml                 # Cordova配置文件
├── hooks/                     # 自定义钩子脚本
├── platforms/                 # 各平台构建文件
├── plugins/                   # 插件目录
├── www/                       # Web资源目录
│   ├── index.html            # 主页面
│   ├── css/                  # 样式文件
│   ├── js/                   # JavaScript文件
│   └── icons/                # 应用图标
└── resources/                 # 应用资源
```

### 3. 复制Web应用代码
```bash
# 将PWA应用的HTML、CSS、JS文件复制到www目录
cp -r ../cable_calculator_app/* www/

# 确保所有资源路径正确
```

## 配置优化

### config.xml - 应用配置

```xml
<?xml version='1.0' encoding='utf-8'?>
<widget id="com.hongteng.cablecalculator" version="1.0.0" xmlns="http://www.w3.org/ns/widgets" xmlns:cdv="http://cordova.apache.org/ns/1.0">
    <name>红腾电气电缆计算器</name>
    <description>专业电缆计算工具</description>
    <author email="developer@hongteng.com" href="https://hongteng.com">红腾电气</author>

    <!-- 内容安全策略 -->
    <content-security-policy>
        <access-origin="*" />
        <allow-navigation href="*" />
        <allow-intent href="http://*/*" />
        <allow-intent href="https://*/*" />
        <allow-intent href="tel:*" />
        <allow-intent href="sms:*" />
        <allow-intent href="mailto:*" />
        <allow-intent href="geo:*" />
    </content-security-policy>

    <!-- 平台配置 -->
    <platform name="android">
        <allow-intent href="market:*" />
        <icon density="ldpi" src="resources/android/icon.png" />
        <icon density="mdpi" src="resources/android/icon.png" />
        <icon density="hdpi" src="resources/android/icon.png" />
        <icon density="xhdpi" src="resources/android/icon.png" />
        <icon density="xxhdpi" src="resources/android/icon.png" />
        <icon density="xxxhdpi" src="resources/android/icon.png" />
        
        <!-- Android特定配置 -->
        <edit-config file="app/src/main/AndroidManifest.xml" mode="merge" target="/manifest/application">
            <application android:theme="@style/AppTheme" />
        </edit-config>
    </platform>

    <platform name="ios">
        <allow-intent href="itms:*" />
        <allow-intent href="itms-apps:*" />
        <icon height="57" platform="ios" src="resources/ios/icon.png" width="57" />
        <icon height="114" platform="ios" src="resources/ios/icon.png" width="114" />
        <icon height="40" platform="ios" src="resources/ios/icon.png" width="40" />
        <icon height="80" platform="ios" src="resources/ios/icon.png" width="80" />
        <icon height="120" platform="ios" src="resources/ios/icon.png" width="120" />
        <icon height="180" platform="ios" src="resources/ios/icon.png" width="180" />
    </platform>

    <!-- 插件配置 -->
    <plugin name="cordova-plugin-whitelist" spec="1" />
    <plugin name="cordova-plugin-network-information" spec="3" />
    <plugin name="cordova-plugin-device" spec="2" />
    <plugin name="cordova-plugin-statusbar" spec="3" />
    <plugin name="cordova-plugin-splashscreen" spec="6" />
    
    <!-- 自定义插件示例 -->
    <plugin name="cordova-plugin-custom-share" spec="1.0.0">
        <variable name="SHARE_TITLE" value="红腾电气电缆计算器" />
    </plugin>

    <!-- 全局配置 -->
    <access origin="*" />
    <allow-intent href="*" />
    <platform name="browser">
        <allow-intent href="http://*/*" />
        <allow-intent href="https://*/*" />
        <allow-intent href="tel:*" />
        <allow-intent href="sms:*" />
        <allow-intent href="mailto:*" />
        <allow-intent href="geo:*" />
    </platform>
</widget>
```

### 优化www/index.html

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <meta name="format-detection" content="telephone=no">
    <meta name="msapplication-tap-highlight" content="no">
    <title>红腾电气电缆计算器</title>

    <!-- Cordova -->
    <script type="text/javascript" src="cordova.js"></script>
    
    <!-- 应用样式 -->
    <link rel="stylesheet" type="text/css" href="css/index.css">
    
    <!-- 应用脚本 -->
    <script type="text/javascript" src="js/app.js"></script>
</head>

<body>
    <div class="app">
        <!-- 原有的HTML内容 -->
        <header class="app-header">
            <h1>红腾电气电缆计算器</h1>
        </header>
        
        <!-- 主要内容 -->
        <main class="app-main">
            <!-- 这里是原来的计算器界面 -->
        </main>
    </div>

    <script type="text/javascript">
        app.initialize();

        // 设备就绪事件
        document.addEventListener('deviceready', function() {
            console.log('Cordova设备就绪');
            
            // 设置状态栏样式
            if (navigator.userAgent.match(/(iPhone|iPod|iPad|Android|BlackBerry|IEMobile)/)) {
                StatusBar.overlaysWebView(false);
                StatusBar.styleLightContent();
                StatusBar.backgroundColorByHexString("#0f2027");
            }
            
            // 初始化应用功能
            app.onDeviceReady();
        }, false);
    </script>
</body>
</html>
```

### 优化JavaScript (js/index.js)

```javascript
var app = {
    // 应用初始化
    initialize: function() {
        this.bindEvents();
    },
    
    // 绑定事件
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
        document.addEventListener('resume', this.onResume, false);
        document.addEventListener('pause', this.onPause, false);
    },
    
    // 设备就绪
    onDeviceReady: function() {
        console.log('设备就绪');
        
        // 隐藏启动画面
        if (navigator.splashscreen) {
            navigator.splashscreen.hide();
        }
        
        // 启用网络监控
        this.setupNetworkListener();
        
        // 设置分享功能
        this.setupShareFunction();
    },
    
    // 应用恢复
    onResume: function() {
        console.log('应用恢复');
    },
    
    // 应用暂停
    onPause: function() {
        console.log('应用暂停');
    },
    
    // 设置网络监听
    setupNetworkListener: function() {
        if (navigator.connection) {
            function checkConnection() {
                var connection = navigator.connection.type;
                var states = {};
                states[Connection.UNKNOWN]  = 'Unknown connection';
                states[Connection.ETHERNET] = 'Ethernet connection';
                states[Connection.WIFI]     = 'WiFi connection';
                states[Connection.CELL_2G]  = 'Cell 2G connection';
                states[Connection.CELL_3G]  = 'Cell 3G connection';
                states[Connection.CELL_4G]  = 'Cell 4G connection';
                states[Connection.CELL]     = 'Cell generic connection';
                states[Connection.NONE]     = 'No network connection';
                
                console.log('网络状态:', states[connection]);
            }
            
            checkConnection();
            document.addEventListener("connection", checkConnection, false);
        }
    },
    
    // 设置分享功能
    setupShareFunction: function() {
        // 将分享功能绑定到全局
        window.shareResult = function(content) {
            if (navigator.share) {
                navigator.share({
                    title: '电缆计算结果',
                    text: content,
                    url: window.location.href
                }).then(() => console.log('分享成功'))
                  .catch((error) => console.log('分享失败', error));
            } else {
                // 使用cordova-plugin-custom-share
                window.plugins.socialsharing.share(
                    content,
                    '电缆计算结果',
                    null,
                    null
                );
            }
        };
    }
};
```

## 插件开发

### 自定义分享插件 (plugins/cordova-plugin-custom-share/www/share.js)

```javascript
exports.share = function(success, fail, args) {
    var content = args[0];
    var title = args[1];
    var image = args[2];
    var url = args[3];
    
    // 根据平台实现分享逻辑
    cordova.exec(success, fail, "CustomShare", "share", [content, title, image, url]);
};
```

### Android原生实现 (plugins/cordova-plugin-custom-share/src/android/CustomShare.java)

```java
package com.hongteng.cablecalculator;

import android.content.Intent;
import android.content.Context;
import android.widget.Toast;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import android.content.Intent;

public class CustomShare extends CordovaPlugin {
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("share")) {
            String content = args.getString(0);
            String title = args.getString(1);
            this.shareContent(content, title, callbackContext);
            return true;
        }
        return false;
    }
    
    private void shareContent(String content, String title, CallbackContext callbackContext) {
        if (content != null && content.length() > 0) {
            Intent sendIntent = new Intent();
            sendIntent.setAction(Intent.ACTION_SEND);
            sendIntent.putExtra(Intent.EXTRA_TEXT, content);
            sendIntent.putExtra(Intent.EXTRA_SUBJECT, title);
            sendIntent.setType("text/plain");
            
            Intent shareIntent = Intent.createChooser(sendIntent, "分享到");
            cordova.getActivity().startActivity(shareIntent);
            
            callbackContext.success("分享成功");
        } else {
            callbackContext.error("分享内容不能为空");
        }
    }
}
```

## 构建和发布

### 1. 添加图标和启动画面

```bash
# 安装图标插件
cordova plugin add cordova-plugin-splashscreen

# 生成不同尺寸的图标
# 可以使用在线工具或插件自动生成
```

### 2. 调试构建

```bash
# 添加调试模式
cordova build android --debug
cordova build ios --debug

# 运行在模拟器上
cordova emulate android
cordova emulate ios
```

### 3. 发布构建

```bash
# Android发布版
cordova build android --release -- --keystore=/path/to/keystore --storepassword=password --alias=alias_name

# iOS发布版
cordova build ios --release
```

### 4. 签名配置

创建 `build.json` 配置文件：

```json
{
    "android": {
        "release": {
            "keystore": "/path/to/release.keystore",
            "storePassword": "your_store_password",
            "alias": "your_alias_name",
            "password": "your_alias_password",
            "keystoreType": "pkcs12"
        }
    },
    "ios": {
        "release": {
            "codeSignIdentity": "iPhone Distribution",
            "provisioningProfile": "your_provisioning_profile_uuid",
            "developmentTeam": "your_development_team_id"
        }
    }
}
```

## 性能优化

### 1. 代码优化
- 压缩CSS和JavaScript文件
- 优化图片资源
- 使用图标字体代替图片

### 2. 缓存策略
```xml
<!-- 在config.xml中配置 -->
<preference name="SplashMaintainAspectRatio" value="true" />
<preference name="FadeSplashScreenDuration" value="300" />
<preference name="SplashShowOnlyFirstTime" value="false" />
```

### 3. 网络优化
- 实现离线缓存
- 预加载关键资源
- 使用CDN加速

## 鸿蒙系统适配

### 1. 鸿蒙特定配置
```xml
<!-- 在config.xml中添加鸿蒙平台 -->
<platform name="harmonyos">
    <allow-intent href="market:*" />
    <icon density="ldpi" src="resources/harmonyos/icon.png" />
    <!-- 更多鸿蒙特定配置 -->
</platform>
```

### 2. 测试兼容性
- 在鸿蒙设备上测试所有功能
- 检查WebView兼容性
- 验证原生插件功能

## 部署到应用商店

### 1. 华为应用市场 (HarmonyOS)
- 注册华为开发者账号
- 上传应用包
- 填写应用信息
- 提交审核

### 2. Google Play (Android)
- 注册Google Play开发者账号
- 上传AAB/APK文件
- 配置商店信息
- 提交审核

### 3. Apple App Store (iOS)
- 注册Apple开发者账号
- 通过Xcode上传应用
- 填写App Store信息
- 提交审核

这种方案适合需要发布到多个应用商店，并且需要原生功能的商业应用场景。

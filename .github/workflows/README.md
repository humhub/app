# Deployment process

[📁 Workflow](https://github.com/humhub/app/blob/master/.github/workflows/version-release.yml)

This document will walk you through the steps we take to deploy our mobile app to both the Play Store and App Store.

Deploying an app is a crucial step in any software development project. It can often be complex and time-consuming, but with the help of Github Actions, we have made it much more efficient and streamlined. In this file, we will provide a detailed overview of our deployment process. We will cover the tools and technologies we use, as well as the steps we take to deploy our app to both the Play Store and App Store. Our hope is that this document will be useful to other developers who are looking to streamline their deployment process and make it more efficient. So let's dive in!

## Create version number

**[⚙️](https://emojipedia.org/gear/)** [Job](https://github.com/humhub/app/blob/master/.github/workflows/version-release.yml#:~:text=version%3A,%3A%20version.txt): `version`

This job handles the creation of a `version.txt` file for a project by extracting the version from a git tag, writing it to a file, and uploading the file as an artifact.

### Job

**`Extract version from tag name`** step extracts the version number from the tag name. It uses a combination of the **`echo`** and **`sed`** commands to remove the leading **`v`** and any additional text after a dash (**``**) in the tag name.

**`Write version to file`** step writes the version number to a file named **`version.txt`**.

**`Upload version.txt`** step uploads the **`version.txt`** file as an artifact.

## Build APK

**[⚙️](https://emojipedia.org/gear/)** [Job](https://github.com/humhub/app/blob/master/.github/workflows/version-release.yml#:~:text=build_android%3A,%3A%20build/app/outputs/bundle/release/app%2Drelease.aab) : `build_android`

This job generates an APK and app bundle files for Google Play Store, then creates a GitHub release with the built artifacts.

### P**rerequisite**

To publish the app to the Play Store, we need to give your app a digital signature using a keystore. Follow [this official Flutter Doc](https://docs.flutter.dev/deployment/android#create-an-upload-keystore). on how to do that depending upon your machine:

```bash
keytool -genkey -v -keystore %userprofile%\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

This will create a file with a `.jks` extension in your home directory or whatever path you provided.

For the purpose of using this **`keystore.jks`** key inside our CI process, it needs to be converted into a base64 string.

```php
openssl base64 -in keystore.jks -out keystore_base64.txt
```

*N.B., make sure to add the store password, key password, and keystore in your GitHub repository secrets (from GitHub repository > Secrets > Actions)*

**`PLAYSTORE_KEYSTORE_BASE64`**value is the content of a `keystore_base64.txt` that we generated in the previous step.
**`PLAYSTORE_KEY_PASSWORD`** is the key password that we chose to use when generating the .jks file
**`PLAYSTORE_STORE_PASSWORD`**is the store password that we chose to use when generating the .jks file

### Job

**`needs`** the **`version`** job to complete.

`permissions` are set to `write` so that we can upload the APKs files once they are created.

**`Update version in YAML`**step updates the **`version`** and **`versionCode`** fields in the **`pubspec.yaml`** with the values extracted in previous steps. Google Play as also App Store requires that the version code of a new release should always be greater than the previously deployed version code. This ensures that Google Play can distribute the build effectively among users and allows us to upload multiple APKs with the same version to the Play Store.

**`Create key.properties file and write secrets to it`** creates a **`key.properties`** file and writes the necessary secrets to it.

**`Convert base64 to keystore.jks`**step decodes the base64-encoded keystore and saves it to the **`keystore.jks`** file. This file will be used for signing the APKs. [How to sign APK.](https://developer.android.com/studio/publish/app-signing)

**`Setup Flutter`**sets up Flutter on the virtual machine.

**`Android Version Actions`** sets the version code and version name in the Android project.

**`flutter pub get`** installs the dependencies.

**`flutter analyze`** runs the static code analysis on the codebase.

**`flutter build apk`** builds the APK and signs it for release.

**`flutter build appbundle`** builds the app bundle and signs it for release.

**`Upload app bundle`** uploads the app bundle and APK as an artifact to Github release

## Release APK to Google Play

**[⚙️](https://emojipedia.org/gear/)** [Job](https://github.com/humhub/app/blob/master/.github/workflows/version-release.yml#:~:text=release_android%3A,status%3A%20completed) : `release_android`

This job handles the automation of the release process of an Android app to the Google Play Store.

### P**rerequisite**

This job requires a Google service account with `PLAYSTORE_ACCOUNT_KEY` which will be used in GitHub Actions to publish the Android build to the Play Store, so to create a project in GCP, [create a service account](https://console.cloud.google.com/iam-admin/serviceaccounts/project) and select your created project.

1. Log in to the Google Play Console with your developer account.
2. Select the app that you want to upload the app bundle for.
3. Go to the "Settings" tab and then select "Developer account" from the left-hand menu.
4. Under "API access," click on "Create service account."
5. Enter a name for your service account and select "JSON" as the key type.
6. Click on "Create" to generate and download the key file.

Now that you have created the service account and downloaded the key file, you will need to grant the necessary permissions to the service account.

Here are the steps to follow:

1. Go to the "Users and permissions" section of the Google Play Console.
2. Click on "Invite new user" and enter the email address associated with the service account.
3. Select the "Release Manager" role for the service account.
4. Click on "Send invitation."

Once the service account has been granted the "Release Manager" role, it will have the necessary permissions to upload the app bundle and its key to the Google Play Store.

*N.B., make sure to add the* `PLAYSTORE_ACCOUNT_KEY` *in your GitHub repository secrets (from GitHub repository > Secrets > Actions)*

**`PLAYSTORE_ACCOUNT_KEY`:** value is the content of a key that we downloaded from Google Play Console in the previous step.

### Job

**`needs`** the `build_android`job to complete.

This step uses the **`r0adkll/upload-google-play@v1`** action to release the app to the internal track on the Google Play Store. The following parameters are provided for the action:

- **`serviceAccountJsonPlainText`**is a secret value that is retrieved from the GitHub repository secrets. It contains the JSON file of the service account key that grants the action access to the Google Play Console.
- **`packageName`**is the package name of the app to be released.
- **`releaseFiles`** is the name of the app bundle file to be uploaded. In our case, it is **`app-release.aab`**.
- **`track`**specifies the release track of the app. In our case, it’s set to **`internal`**.
- **`status`**specifies the status of the release. In our case, it’s set to **`completed`**.

## Build IPA

**[⚙️](https://emojipedia.org/gear/)** [Job](https://github.com/humhub/app/blob/master/.github/workflows/version-release.yml#:~:text=build_ios%3A,Profiles/build_pp.mobileprovision): `build_ios`

This job automates the process of building an IPA file for iOS and then creates a GitHub release with the built artifacts.

### P**rerequisite**

For building an IPA file that will be deployed we need these 4 values saved in GitHub secrets :

```yaml
BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
BUILD_PROVISION_PROFILE_BASE64: ${{ secrets.BUILD_PROVISION_PROFILE_BASE64 }}
KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
```

1. **BUILD_CERTIFICATE_BASE64 and P12_PASSWORD**

   Build certificate is a digital certificate used to sign an iOS app for distribution through the App Store. The certificate is issued by Apple and tied to a specific developer account. It allows the developer to certify that the app has not been tampered with and comes from a trusted source. This is important for security reasons and to ensure that users can trust the app they are downloading. The certificate is used as part of the app submission process to the App Store and must be included in the app bundle before it can be uploaded to the store.

   1.1 Follow the instructions on [how to create and export the P12 build certificate.](https://support.magplus.com/hc/en-us/articles/203808748-iOS-Creating-a-Distribution-Certificate-and-p12-File)

   1.2 If following the instructions correctly you ended up with **`certificate.p12`** file and a password that was used when generating it.

   1.3 Now you need to convert that p12 file to a base64 string and copy it to GitHub secrets under `BUILD_CERTIFICATE_BASE64` key.

    ```bash
    openssl base64 -in keystore.jks -out build_cert_base64.txt
    ```

   1.4  Also copy the password we secured our certificate with to GitHub Secret with key `P12_PASSWORD`.

2. **BUILD_PROVISION_PROFILE_BASE64**

   A provisioning profile authorizes your app to use certain app services and ensures that you're a known developer developing, uploading, or distributing your app.
   A provisioning profile contains a single App ID that matches one or more of your apps and a distribution certificate.

   2.1 Follow the instructions on [how to create a Provisioning Profile of Type App Store](https://support.staffbase.com/hc/en-us/articles/115003598691-Creating-the-iOS-Provisioning-Profiles#:~:text=Creating%20the%20Provisioning%20Profile%20of%20Type%20App%20Store)

   2.2 Download it from App Store and convert it to base64 string and import that to GitHub Secrets under the `BUILD_PROVISION_PROFILE_BASE64`

3. KEYCHAIN_PASSWORD

   When building an IPA file, the Keystore and certificates are always removed from the build at the end. However, to ensure its security during the build process, we utilize a randomly generated string (password) as a protective measure for the Keystore.

   Select any password that you would like.


### Job

The **`checkout`** step uses the **`actions/checkout@v3`** action to checkout the repository to the runner's file system.

**`Install the Apple certificate and provisioning profile`I**mport the necessary Apple certificate and provisioning profile for building the app. The step creates a temporary keychain, imports the certificate to the keychain, applies the provisioning profile, and copies it to the required location.

**`Install Flutter`**step uses the **`subosito/flutter-action@v1`** action to install the required version of Flutter.

**`Install pub dependencies`** step installs the dependencies required by the app.

**`Extract version and version code`** step extracts the version and version code from the Git tag and stores them in environment variables. this will be used to define a version and build a number of IPA build.

**`Build IPA`** step builds the IPA for the app in release mode.

**`Create release`** step uses the **`ncipollo/release-action@v1`** action to create a release and upload the IPA file as an artifact.

**`Clean up keychain and provisioning profile`** step removes the temporary keychain and provisioning profile from the runner.

## Release IPA to TestFlight

This job releases an iOS app to TestFlight for beta testing. It downloads the IPA file as an artifact from GitHub Release and uploads it to TestFlight for distribution.

### P**rerequisite**

First, you will need to set up the App Store Publishing Key

1. Open the **[App Store Connect](https://appstoreconnect.apple.com/)**.
2. Click on the **Users and Access** tab.
3. Click on the **Keys** tab.
4. Click on the **+** button to add a new key.
5. Fill in the name and description for the key.
6. Select the **Access to API** checkbox.
7. Click on the **Generate** button.
8. Download the private key and store it securely.

Now the values we need to define in Github Secrets are as folows:

`APP_API_ISSUER_ID` (Blue) and `APPSTORE_API_KEY_ID` (Brown) the last `APP_API_PRIVATE_KEY` is a content of a file you downloaded in 8th step.

![Untitled](Deployment%20process%202a4bebc773f843b5979d692c92ad7a62/Untitled.png)

### Job

1. **`Get IPA from artifacts`**step downloads the IPA file produced by the **`build_ios`** job from the artifacts and stores it in the **`build/ios/ipa`** directory.
2. **`Upload app to TestFlight`** step uses the **`apple-actions/upload-testflight-build`** action to upload the IPA file to TestFlight for beta testing. The **`app-path`** field specifies the path to the IPA file, while the **`issuer-id`**, **`api-key-id`**, and **`api-private-key`** fields are authentication credentials required to access the App Store Connect API.

### Play Console status

Once the Google Play pipeline succeeds, the latest app bundle build will undergo internal testing before potentially advancing to Closed Open testing or Production. Our decision to deploy new builds to the internal testing track is due to the fact that it does not require review from the Google Play store, making it immediately accessible to testers.

![Untitled](Deployment%20process%202a4bebc773f843b5979d692c92ad7a62/Untitled%201.png)

### App Store status

In order to push your app to internal testing on the app store, there are some additional steps you must follow. First, you need to agree to the necessary compliances. Then, click on `Manage` and select `None` for the mentioned algorithms before saving. If the `Track Alpha` option is not visible, you must manually add it by clicking on the `+` and creating a new column called `Groups` under the selected build.

![Untitled](Deployment%20process%202a4bebc773f843b5979d692c92ad7a62/Untitled%202.png)

## The End

Congratulations on acquiring the knowledge to automate the signing and delivery process of your app! While it may require some extra effort at the beginning, implementing a CI/CD workflow will pay off in the future. Consider the benefits of not having to perform additional tasks each time you push a new build of your app.
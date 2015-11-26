/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *
 * Copyright (c) 2012-2014 HockeyApp, Bit Stadium GmbH.
 * Copyright (c) 2011 Andreas Linde.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "HockeySDK.h"
#import "HockeySDKPrivate.h"
#include <CommonCrypto/CommonDigest.h>

NSString *const kBITCrashErrorDomain = @"BITCrashReporterErrorDomain";
NSString *const kBITUpdateErrorDomain = @"BITUpdaterErrorDomain";
NSString *const kBITFeedbackErrorDomain = @"BITFeedbackErrorDomain";
NSString *const kBITHockeyErrorDomain = @"BITHockeyErrorDomain";
NSString *const kBITAuthenticatorErrorDomain = @"BITAuthenticatorErrorDomain";

// Load the framework bundle.
NSBundle *BITHockeyBundle(void) {
  static NSBundle *bundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    NSString* mainBundlePath = [[NSBundle bundleForClass:[BITHockeyManager class]] resourcePath];
    NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:BITHOCKEYSDK_BUNDLE];
    bundle = [NSBundle bundleWithPath:frameworkBundlePath];
  });
  return bundle;
}

//Load the CFBundleVersion checking for the override if there is one in HockeyAppVersion
NSString *BITCurrentAppVersion(void) {
  static NSString *currentVersion = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"HockeyAppVersion"];
    if (!currentVersion)
      currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
  });
  return currentVersion;
}

static NSString *BITHockeyLocalizedStringFromBundleInTable(NSString *stringToken, NSBundle *bundle, NSString *tableName)
{
  if (bundle != nil && tableName != nil) {
    NSString *bundleSpecificLocalizationString = NSLocalizedStringFromTableInBundle(stringToken, tableName, bundle, @"");
    if (bundleSpecificLocalizationString)
      return bundleSpecificLocalizationString;
  }
  return stringToken;
}

NSString *BITHockeyLocalizedString(NSString *stringToken) {
  if (!stringToken) return @"";

  NSString *appSpecificLocalizationString = NSLocalizedString(stringToken, @"");
  if (appSpecificLocalizationString && ![stringToken isEqualToString:appSpecificLocalizationString]) {
    return appSpecificLocalizationString;
  }
  NSBundle *bundle;
  NSString *tableName = @"HockeySDK";
  NSString *localizedString;
  BOOL haveOverride = ([[BITHockeyManager sharedHockeyManager] bundleTableOverride] != nil) && ([[BITHockeyManager sharedHockeyManager] bundleOverride] != nil);
  
  if (haveOverride)
      {
      tableName = [[BITHockeyManager sharedHockeyManager] bundleTableOverride];
      bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:[[BITHockeyManager sharedHockeyManager] bundleOverride] ofType:@"bundle"]];
      localizedString = BITHockeyLocalizedStringFromBundleInTable(stringToken, bundle, tableName);
      if (localizedString != nil && ![localizedString isEqualToString:stringToken])
        return localizedString;
      }
  
  tableName = @"HockeySDK";
  bundle = BITHockeyBundle();
  return BITHockeyLocalizedStringFromBundleInTable(stringToken, bundle, tableName);

}

NSString *BITHockeyMD5(NSString *str) {
  NSData *utf8Bytes = [str dataUsingEncoding:NSUTF8StringEncoding];
  unsigned char result[CC_MD5_DIGEST_LENGTH] = {0};
  CC_MD5( utf8Bytes.bytes, (CC_LONG)utf8Bytes.length, result );
  return [NSString
          stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
          result[0], result[1],
          result[2], result[3],
          result[4], result[5],
          result[6], result[7],
          result[8], result[9],
          result[10], result[11],
          result[12], result[13],
          result[14], result[15]
          ];
}

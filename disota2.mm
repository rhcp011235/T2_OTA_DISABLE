#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <unistd.h>

#pragma mark - Shell Helpers

NSString* executeCommand(NSString* command) {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", command];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    [task launch];
    [task waitUntilExit];

    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - OTA Plist Blocking

void blockOTAWithPlist(NSArray<NSString*> *paths) {
    for (NSString *path in paths) {
        NSLog(@"[+] Processing plist: %@", path);

        NSMutableDictionary *plist =
            [NSMutableDictionary dictionaryWithContentsOfFile:path];

        if (!plist) {
            plist = [NSMutableDictionary dictionary];
        }

        plist[@"AutomaticCheckEnabled"]      = @NO;
        plist[@"AutomaticDownload"]          = @NO;
        plist[@"CriticalUpdateInstall"]       = @NO;
        plist[@"ConfigDataInstall"]           = @NO;
        plist[@"AutoUpdate"]                  = @NO;
        plist[@"AutoUpdateRestartRequired"]   = @NO;
        plist[@"ScheduleFrequency"]           = @0;

        BOOL success = [plist writeToFile:path atomically:YES];
        NSLog(success ? @"[+] Wrote plist successfully" : @"[-] Failed to write plist");
    }
}

#pragma mark - System Cleanup

void cleanupSystem(void) {
    NSLog(@"[+] Killing update daemons");
    executeCommand(@"killall -9 softwareupdated 2>/dev/null");
    executeCommand(@"killall -9 com.apple.MobileSoftwareUpdate 2>/dev/null");

    NSLog(@"[+] Removing cached updates");
    executeCommand(@"rm -rf /Library/Updates/*");
    executeCommand(@"rm -rf /var/db/softwareupdate/*");
}

#pragma mark - Disable OTA

void disableOTA(void) {
    if (getuid() != 0) {
        NSLog(@"[-] Must be run as root");
        return;
    }

    NSArray *plists = @[
        @"/Library/Preferences/com.apple.SoftwareUpdate.plist",
        @"/Library/Preferences/com.apple.commerce.plist",
        @"/Library/Managed Preferences/com.apple.SoftwareUpdate.plist",
        @"/var/db/softwareupdate/journal.plist"
    ];

    NSLog(@"[+] Blocking OTA via plist");
    blockOTAWithPlist(plists);

    NSLog(@"[+] Cleaning system update cache");
    cleanupSystem();

    NSLog(@"[+] Unloading softwareupdate daemon");
    executeCommand(@"launchctl unload -w /System/Library/LaunchDaemons/com.apple.softwareupdated.plist");

    NSLog(@"[✓] OTA updates DISABLED");
}

#pragma mark - Enable OTA

void enableOTA(void) {
    if (getuid() != 0) {
        NSLog(@"[-] Must be run as root");
        return;
    }

    NSArray *plists = @[
        @"/Library/Preferences/com.apple.SoftwareUpdate.plist",
        @"/Library/Preferences/com.apple.commerce.plist",
        @"/Library/Managed Preferences/com.apple.SoftwareUpdate.plist",
        @"/var/db/softwareupdate/journal.plist"
    ];

    NSLog(@"[+] Removing OTA blocking plists");
    for (NSString *path in plists) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }

    NSLog(@"[+] Restarting softwareupdate daemon");
    executeCommand(@"launchctl kickstart -k system/com.apple.softwareupdated");

    NSLog(@"[✓] OTA updates ENABLED");
}

#pragma mark - Main

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        NSString *processName = [[NSProcessInfo processInfo] processName];
        if (![processName isEqualToString:@"Disable_OTA_MACOS"]) {
            NSLog(@"[-] Invalid binary name");
            return 1;
        }

        printf("\nDisable macOS OTA Updates\n");
        printf("1) Disable OTA\n");
        printf("2) Enable OTA\n");
        printf("3) Exit\n");
        printf("> ");

        char choice = 0;
        scanf(" %c", &choice);

        switch (choice) {
            case '1':
                disableOTA();
                break;
            case '2':
                enableOTA();
                break;
            default:
                printf("Exiting\n");
                break;
        }
    }
    return 0;
}

//
//  IAILogger.h
//  InAppInstrumentation
//
//  Created by Santthosh on 10/16/12.
//  Copyright (c) 2012 Santthosh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IAIDataStructures.h"

@class IAIDeviceLogEntry;
@class IAIConsoleLogEntry;
@class IAIEventLogEntry;

extern NSString* const IAILoggerDidAddConsoleLog;

/**
 * The Overview logger.
 *
 *      @ingroup Overview-Logger
 *
 * This object stores all of the historical information used to draw the graphs in the
 * Overview memory and disk pages, as well as the console log page.
 *
 * The primary log should be accessed by calling [IAI @link IAI::logger logger@endlink].
 */
@interface IAILogger : NSObject {
@private
    IAILinkedList* _deviceLogs;
    IAILinkedList* _consoleLogs;
    IAILinkedList* _eventLogs;
    NSTimeInterval _oldestLogAge;
}

#pragma mark Configuration Settings /** @name Configuration Settings */

/**
 * The oldest age of a memory or disk log entry.
 *
 * Log entries older than this number of seconds will be pruned from the log.
 *
 * By default this is 1 minute.
 */
@property (nonatomic, readwrite, assign) NSTimeInterval oldestLogAge;


#pragma mark Adding Log Entries /** @name Adding Log Entries */

/**
 * Add a device log.
 *
 * This method will first prune expired entries and then add the new entry to the log.
 */
- (void)addDeviceLog:(IAIDeviceLogEntry *)logEntry;

/**
 * Add a console log.
 *
 * This method will not prune console log entries.
 */
- (void)addConsoleLog:(IAIConsoleLogEntry *)logEntry;

/**
 * Add a event log.
 *
 * This method will first prune expired entries and then add the new entry to the log.
 */
- (void)addEventLog:(IAIEventLogEntry *)logEntry;


#pragma mark Accessing Logs /** @name Accessing Logs */

/**
 * The linked list of device logs.
 *
 * Log entries are in increasing chronological order.
 */
@property (nonatomic, readonly, IAI_STRONG) IAILinkedList* deviceLogs;

/**
 * The linked list of console logs.
 *
 * Log entries are in increasing chronological order.
 */
@property (nonatomic, readonly, IAI_STRONG) IAILinkedList* consoleLogs;

/**
 * The linked list of events.
 *
 * Log entries are in increasing chronological order.
 */
@property (nonatomic, readonly, IAI_STRONG) IAILinkedList* eventLogs;

@end


/**
 * The basic requirements for a log entry.
 *
 *      @ingroup Overview-Logger-Entries
 *
 * A basic log entry need only define a timestamp in order to be particularly useful.
 */
@interface IAILogEntry : NSObject {
@private
    NSDate* _timestamp;
}

#pragma mark Creating an Entry /** @name Creating an Entry */

/**
 * Designated initializer.
 */
- (id)initWithTimestamp:(NSDate *)timestamp;


#pragma mark Entry Information /** @name Entry Information */

/**
 * The timestamp for this log entry.
 */
@property (nonatomic, readwrite, retain) NSDate* timestamp;

@end


/**
 * A device log entry.
 *
 *      @ingroup Overview-Logger-Entries
 */
@interface IAIDeviceLogEntry : IAILogEntry {
@private
    unsigned long long _bytesOfFreeMemory;
    unsigned long long _bytesOfTotalMemory;
    unsigned long long _bytesOfTotalDiskSpace;
    unsigned long long _bytesOfFreeDiskSpace;
    
    CGFloat _batteryLevel;
    UIDeviceBatteryState _batteryState;
}

#pragma mark Entry Information /** @name Entry Information */

/**
 * The number of bytes of free memory.
 */
@property (nonatomic, readwrite, assign) unsigned long long bytesOfFreeMemory;

/**
 * The number of bytes of total memory.
 */
@property (nonatomic, readwrite, assign) unsigned long long bytesOfTotalMemory;

/**
 * The number of bytes of free disk space.
 */
@property (nonatomic, readwrite, assign) unsigned long long bytesOfFreeDiskSpace;

/**
 * The number of bytes of total disk space.
 */
@property (nonatomic, readwrite, assign) unsigned long long bytesOfTotalDiskSpace;

/**
 * The battery level.
 */
@property (nonatomic, readwrite, assign) CGFloat batteryLevel;

/**
 * The state of the battery.
 */
@property (nonatomic, readwrite, assign) UIDeviceBatteryState batteryState;

@end


/**
 * A console log entry.
 *
 *      @ingroup Overview-Logger-Entries
 */
@interface IAIConsoleLogEntry : IAILogEntry {
@private
    NSString* _log;
}

#pragma mark Creating an Entry /** @name Creating an Entry */

/**
 * Designated initializer.
 */
- (id)initWithLog:(NSString *)log;


#pragma mark Entry Information /** @name Entry Information */

/**
 * The text that was written to the console log.
 */
@property (nonatomic, readwrite, copy) NSString* log;

@end


typedef enum {
    IAIEventDidReceiveMemoryWarning,
} IAIEventType;

/**
 * An event log entry.
 *
 *      @ingroup Overview-Logger-Entries
 */
@interface IAIEventLogEntry : IAILogEntry {
@private
    NSInteger _eventType;
}

#pragma mark Creating an Entry /** @name Creating an Entry */

/**
 * Designated initializer.
 */
- (id)initWithType:(NSInteger)type;


#pragma mark Entry Information /** @name Entry Information */

/**
 * The type of event.
 */
@property (nonatomic, readwrite, assign) NSInteger type;

@end

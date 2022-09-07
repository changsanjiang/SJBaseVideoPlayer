//
//  SJQueue.m
//  Pods
//
//  Created by 畅三江 on 2019/11/13.
//

#import "SJQueue.h"
#include <stdlib.h>

NS_ASSUME_NONNULL_BEGIN
typedef struct SJItem {
    CFTypeRef _Nullable obj;
    struct SJItem *_Nullable next;
} SJItem, *SJItemQueue;

static inline SJItem *
SJCreateItem(id obj) {
    SJItem *item = malloc(sizeof(SJItem));
    item->next = NULL;
    item->obj = CFBridgingRetain(obj);
    return item;
}

static inline void
SJFreeItem(SJItem *item) {
    if ( item != NULL ) {
        if ( item->obj != NULL ) {
            CFRelease(item->obj);
            item->obj = NULL;
        }
        free(item);
    }
}

@interface SJQueue ()
@property (nonatomic, nullable) SJItem *head;
@property (nonatomic, nullable) SJItem *tail;
@end

@implementation SJQueue
+ (instancetype)queue {
    return SJQueue.alloc.init;
}

- (void)dealloc {
    [self empty];
}

- (nullable id)firstObject {
    return _head != nil ? (__bridge id _Nullable)(_head->obj) : nil;
}

- (nullable id)lastObject {
    return _tail != nil ? (__bridge id _Nullable)(_tail->obj) : nil;
}

- (void)enqueue:(id)obj {
    if ( obj != nil ) {
        SJItem *item = SJCreateItem(obj);
        if ( __builtin_expect(_head == NULL, 0) ) {
            _head = item;
        }
        else {
            _tail->next = item;
        }
        _tail = item;
        _size += 1;
    }
}

- (nullable id)dequeue {
    SJItem *_Nullable item = _head;
    if ( item != NULL ) {
        _head = item->next;
        if ( _head == NULL ) {
            _tail = NULL;
        }
        id _Nullable obj = (__bridge id _Nullable)(item->obj);
        SJFreeItem(item);
        _size -= 1;
        return obj;
    }
    return nil;
}

- (void)empty {
    while ( _head != NULL ) [self dequeue];
}
@end

@implementation SJSafeQueue {
    dispatch_semaphore_t _lock;
}
- (instancetype)init {
    self = [super init];
    if ( self ) {
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (nullable id)firstObject {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    id _Nullable obj = [super firstObject];
    dispatch_semaphore_signal(_lock);
    return obj;
}

- (nullable id)lastObject {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    id _Nullable obj = [super lastObject];
    dispatch_semaphore_signal(_lock);
    return obj;
}

- (void)enqueue:(id)obj {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [super enqueue:obj];
    dispatch_semaphore_signal(_lock);
}

- (nullable id)dequeue {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    id obj = [super dequeue];
    dispatch_semaphore_signal(_lock);
    return obj;
}

- (void)empty {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    while ( self.head != NULL ) [super dequeue];
    dispatch_semaphore_signal(_lock);
}
@end
NS_ASSUME_NONNULL_END

//
//  IAIDataStructures.m
//  InAppInstrumentation
//
//  Created by Santthosh on 10/16/12.
//  Copyright (c) 2012 Santthosh. All rights reserved.
//

#import "IAIDataStructures.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "Nimbus requires ARC support."
#endif

// The internal representation of a single node.
@interface IAILinkedListNode : NSObject
@property (nonatomic, readwrite, IAI_STRONG) id object;
@property (nonatomic, readwrite, IAI_STRONG) IAILinkedListNode* prev;
@property (nonatomic, readwrite, IAI_STRONG) IAILinkedListNode* next;
@end

@implementation IAILinkedListNode
@synthesize object = _object;
@synthesize prev = _prev;
@synthesize next = _next;
@end

@interface IAILinkedListLocation()
+ (id)locationWithNode:(IAILinkedListNode *)node;
- (id)initWithNode:(IAILinkedListNode *)node;
@property (nonatomic, readwrite, weak) IAILinkedListNode* node;
@end

@implementation IAILinkedListLocation
@synthesize node = _node;
+ (id)locationWithNode:(IAILinkedListNode *)node {
    return [[self alloc] initWithNode:node];
}
- (id)initWithNode:(IAILinkedListNode *)node {
    if (self = [super init]) {
        _node = node;
    }
    return self;
}
- (BOOL)isEqual:(id)object {
    return ([object isKindOfClass:[IAILinkedListLocation class]]
            && [object node] == self.node);
}
@end

@interface IAILinkedList()
// Exposed so that the linked list enumerator can iterate over the nodes directly.
@property (nonatomic, readonly, IAI_STRONG) IAILinkedListNode* head;
@property (nonatomic, readonly, IAI_STRONG) IAILinkedListNode* tail;
@property (nonatomic, readwrite, assign) NSUInteger count;
@property (nonatomic, readwrite, assign) unsigned long modificationNumber;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @internal
 *
 * A implementation of NSEnumerator for IAILinkedList.
 *
 * This class simply implements the nextObject NSEnumerator method and traverses a linked list.
 * The linked list is retained when this enumerator is created and released once the enumerator
 * is either released or deallocated.
 */
@interface IAILinkedListEnumerator : NSEnumerator {
@private
    IAILinkedList* _ll;
    IAILinkedListNode* _iterator;
}

/**
 * Designated initializer. Retains the linked list.
 */
- (id)initWithLinkedList:(IAILinkedList *)ll;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAILinkedListEnumerator


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
    _iterator = nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithLinkedList:(IAILinkedList *)ll {
    if (self = [super init]) {
        _ll = ll;
        _iterator = ll.head;
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)nextObject {
    id object = nil;
    
    // Iteration step.
    if (nil != _iterator) {
        object = _iterator.object;
        _iterator = _iterator.next;
        
        // Completion step.
    } else {
        // As per the guidelines in the Objective-C docs for enumerators, we release the linked
        // list when we are finished enumerating.
        _ll = nil;
        
        // We don't have to set _iterator to nil here because is already is.
    }
    return object;
}


@end


#pragma mark -


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAILinkedList

@synthesize count = _count;
@synthesize head = _head;
@synthesize tail = _tail;
@synthesize modificationNumber = _modificationNumber;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
    [self removeAllObjects];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Linked List Creation


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (IAILinkedList *)linkedList {
    return [[[self class] alloc] init];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (IAILinkedList *)linkedListWithArray:(NSArray *)array {
    return [[[self class] alloc] initWithArray:array];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithArray:(NSArray *)anArray {
    if ((self = [self init])) {
        for (id object in anArray) {
            [self addObject:object];
        }
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)_setCount:(NSUInteger)count {
    _count = count;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)_removeNode:(IAILinkedListNode *)node {
    if (nil == node) {
        return;
    }
    
    if (nil != node.prev) {
        node.prev.next = node.next;
        
    } else {
        _head = node.next;
    }
    
    if (nil != node.next) {
        node.next.prev = node.prev;
        
    } else {
        _tail = node.prev;
    }
    
    node.next = nil;
    node.prev = nil;
    
    --_count;
    ++_modificationNumber;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCopying


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)copyWithZone:(NSZone *)zone {
    IAILinkedList* copy = [[[self class] allocWithZone:zone] init];
    
    IAILinkedListNode* node = _head;
    
    while (0 != node) {
        [copy addObject:node.object];
        node = node.next;
    }
    
    copy.count = self.count;
    
    return copy;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSCoding


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeValueOfObjCType:@encode(NSUInteger) at:&_count];
    
    IAILinkedListNode* node = _head;
    while (0 != node) {
        [coder encodeObject:node.object];
        node = node.next;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        // We'll let addObject modify the count, so create a local count here so that we don't
        // double count every object.
        NSUInteger count = 0;
        [decoder decodeValueOfObjCType:@encode(NSUInteger) at:&count];
        
        for (NSUInteger ix = 0; ix < count; ++ix) {
            id object = [decoder decodeObject];
            
            [self addObject:object];
        }
        
        // Sanity check.
        IAIDASSERT(count == self.count);
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFastEnumeration


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id *)stackbuf
                                    count:(NSUInteger)len {
    // Initialization condition.
    if (0 == state->state) {
        // Whenever the linked list is modified, the modification number increases. This allows
        // enumeration to bail out if the linked list is modified mid-flight.
        state->mutationsPtr = &_modificationNumber;
    }
    
    NSUInteger numberOfItemsReturned = 0;
    
    // If there is no _tail (i.e. this is an empty list) then this will end immediately.
    if ((void *)state->state != (__bridge void *)_tail) {
        state->itemsPtr = stackbuf;
        
        if (0 == state->state) {
            // Initialize the state here instead of above when we check 0 == state.state because
            // for single item linked lists head == tail. If we initialized it in the initialization
            // condition, state.state != _tail check would fail and we wouldn't return the single
            // object.
            state->state = (unsigned long)_head;
        }
        
        // Return *at most* the number of request objects.
        while ((0 != state->state) && (numberOfItemsReturned < len)) {
            IAILinkedListNode* node = (__bridge IAILinkedListNode *)(void *)state->state;
            stackbuf[numberOfItemsReturned] = node.object;
            state->state = (unsigned long)node.next;
            ++numberOfItemsReturned;
        }
        
        if (0 == state->state) {
            // Final step condition. We allow the above loop to overstep the end one iteration,
            // because we rewind it one step here (to ensure that the next time enumeration occurs,
            // state == _tail.
            state->state = (unsigned long)_tail;
        }
        
    } // else we've returned all of the items that we can; leave numberOfItemsReturned as 0 to
    // signal that there is nothing left to be done.
    
    return numberOfItemsReturned;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Public Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)firstObject {
    return (nil != _head) ? _head.object : nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)lastObject {
    return (nil != _tail) ? _tail.object : nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Extended Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)allObjects {
    NSMutableArray* mutableArrayOfObjects = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    for (id object in self) {
        [mutableArrayOfObjects addObject:object];
    }
    
    return [mutableArrayOfObjects copy];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)containsObject:(id)anObject {
    for (id object in self) {
        if (object == anObject) {
            return YES;
        }
    }
    
    return NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)description {
    // In general we should try to avoid cheating by using allObjects for memory performance reasons,
    // but the description method is complex enough that it's not worth reinventing the wheel here.
    return [[self allObjects] description];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectAtLocation:(IAILinkedListLocation *)location {
    return location.node.object;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSEnumerator *)objectEnumerator {
    return [[IAILinkedListEnumerator alloc] initWithLinkedList:self];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (IAILinkedListLocation *)locationOfObject:(id)object {
    IAILinkedListNode* node = _head;
    while (0 != node) {
        if (node.object == object) {
            return [IAILinkedListLocation locationWithNode:node];
        }
        node = node.next;
    }
    return 0;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeObjectAtLocation:(IAILinkedListLocation *)location {
    if (nil == location) {
        return;
    }
    
    [self _removeNode:location.node];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (IAILinkedListLocation *)addObject:(id)object {
    // nil objects can not be added to a linked list.
    IAIDASSERT(nil != object);
    if (nil == object) {
        return nil;
    }
    
    IAILinkedListNode* node = [[IAILinkedListNode alloc] init];
    node.object = object;
    
    // Empty condition.
    if (nil == _tail) {
        _head = node;
        _tail = node;
        
    } else {
        // Non-empty condition.
        _tail.next = node;
        node.prev = _tail;
        _tail = node;
    }
    
    ++self.count;
    ++_modificationNumber;
    
    return [IAILinkedListLocation locationWithNode:node];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addObjectsFromArray:(NSArray *)array {
    for (id object in array) {
        [self addObject:object];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Mutable Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeAllObjects {
    IAILinkedListNode* node = _head;
    while (nil != node) {
        IAILinkedListNode* next = node.next;
        node.prev = nil;
        node.next = nil;
        node = next;
    }
    
    _head = nil;
    _tail = nil;
    
    self.count = 0;
    ++_modificationNumber;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeObject:(id)object {
    IAILinkedListLocation* location = [self locationOfObject:object];
    if (0 != location) {
        [self removeObjectAtLocation:location];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeFirstObject {
    [self _removeNode:_head];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removeLastObject {
    [self _removeNode:_tail];
}

@end


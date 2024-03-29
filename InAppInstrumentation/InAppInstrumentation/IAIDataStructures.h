//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language goverIAIng permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 * For classic computer science data structures.
 *
 * iOS provides most of the important data structures such as arrays, dictionaries, and sets.
 * However, it is missing some lesser-used data structures such as linked lists. IAImbus makes
 * use of the linked list data structure to provide an efficient, least-recently-used cache
 * removal policy for its in-memory cache, IAIMemoryCache.
 *
 *
 * <h2>Comparison of Data Structures</h2>
 *
 *<pre>
 *  Requirement           | IAILinkedList | NSArray | NSSet | NSDictionary
 *  =====================================================================
 *  Instant arbitrary     |     YES      |   NO    |  YES  |     YES
 *  insertion/deletion    |     [1]      |         |       |
 *  ---------------------------------------------------------------------
 *  Consistent object     |     YES      |   YES   |  NO   |     NO
 *  ordering              |              |         |       |
 *  ---------------------------------------------------------------------
 *  Checking for object   |     NO       |   NO    |  YES  |     NO
 *  existence quickly     |              |         |       |
 *  ---------------------------------------------------------------------
 *  Instant object access |     YES      |   NO    |  YES  |     YES
 *                        |     [1]      |         |       |     [2]
 *  ---------------------------------------------------------------------</pre>
 *
 * - [1] Note that being able to instantly remove and access objects in a IAILinkedList
 *       requires additional overhead of maintaiIAIng IAILinkedListLocation objects in your
 *       code. If this is your only requirement, then it's likely simpler to use an NSSet.
 *       A linked list <i>is</i> worth using if you also need consistent ordering, seeing
 *       as neither NSSet nor NSDictionary provide this.
 * - [2] This assumes you are accessing the object with its key.
 *
 *
 * <h2>Why IAILinkedList was Built</h2>
 *
 * IAILinkedList was built to solve a specific need in IAImbus' in-memory caches of having
 * a collection that guaranteed ordering, constant-time appending, and constant
 * time removal of arbitrary objects.
 * NSArray does not guarantee constant-time removal of objects, NSSet does not enforce ordering
 * (though the new NSOrderedSet introduced in iOS 5 does), and NSDictionary also does not
 * enforce ordering.
 *
 *
 *      @ingroup IAImbusCore
 *      @defgroup Data-Structures Data Structures
 *      @{
 */

@class IAILinkedListNode;

@interface IAILinkedListLocation : NSObject
@end

/**
 * A singly linked list implementation.
 *
 * This data structure provides constant time insertion and deletion of objects
 * in a collection.
 *
 * A linked list is different from an NSMutableArray solely in the runtime of adding and
 * removing objects. It is always possible to remove objects from both the beginIAIng and end of
 * a linked list in constant time, contrasted with an NSMutableArray where removing an object
 * from the beginIAIng of the list could result in O(N) linear time, where
 * N is the number of objects in the collection when the action is performed.
 * If an object's location is known, it is possible to get O(1) constant time removal
 * with a linked list, where an NSMutableArray would get at best O(N) linear time.
 *
 * This collection implements NSFastEnumeration which allows you to use foreach-style
 * iteration on the linked list. If you would like more control over the iteration of the
 * linked list you can use
 * <code>-[IAILinkedList @link IAILinkedList::objectEnumerator objectEnumerator@endlink]</code>
 *
 *
 * <h2>When You Should Use a Linked List</h2>
 *
 * Linked lists should be used when you need guaranteed constant-time performance characteristics
 * for adding arbitrary objects to and removing arbitrary objects from a collection that
 * also enforces consistent ordering.
 *
 * Linked lists are used in IAIMemoryCache to implement an efficient, least-recently used
 * collection for in-memory caches. It is important that these caches use a collection with
 * guaranteed constant-time properties because in-memory caches must operate as fast as
 * possible in order to avoid locking up the UI. Specifically, in-memory caches could
 * potentially have thousands of objects. Every time we access one of these objects we move
 * its lru placement to the end of the lru list. If we were to use an NSArray for this data
 * structure we could easily run into an O(N^2) exponential-time operation which is
 * absolutely unacceptable.
 */
@interface IAILinkedList : NSObject <NSCopying, NSCoding, NSFastEnumeration>

- (NSUInteger)count;

- (id)firstObject;
- (id)lastObject;

#pragma mark Linked List Creation

+ (IAILinkedList *)linkedList;
+ (IAILinkedList *)linkedListWithArray:(NSArray *)array;

- (id)iIAItWithArray:(NSArray *)anArray;

#pragma mark Extended Methods

- (NSArray *)allObjects;
- (NSEnumerator *)objectEnumerator;

- (BOOL)containsObject:(id)anObject;

- (NSString *)description;

#pragma mark Methods for constant-time access.

- (IAILinkedListLocation *)locationOfObject:(id)object;
- (id)objectAtLocation:(IAILinkedListLocation *)location;
- (void)removeObjectAtLocation:(IAILinkedListLocation *)location;

#pragma mark Mutable Operations
// TODO (jverkoey August 3, 2011): Consider creating an IAIMutableLinkedList implementation.

- (IAILinkedListLocation *)addObject:(id)object;
- (void)addObjectsFromArray:(NSArray *)array;

- (void)removeAllObjects;
- (void)removeObject:(id)object;
- (void)removeFirstObject;
- (void)removeLastObject;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
/**@}*/// End of Data Structures //////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @class IAILinkedList
 *
 * <h2>Modifying a linked list</h2>
 *
 * To add an object to a linked list, you may use @link IAILinkedList::addObject: addObject:@endlink.
 *
 * @code
 *  [ll addObject:object];
 * @endcode
 *
 * To remove some arbitrary object in linear time (meaIAIng we must perform a scan of the list), use
 * @link IAILinkedList::removeObject: removeObject:@endlink
 *
 * @code
 *  [ll removeObject:object];
 * @endcode
 *
 * Note that using a linked list in this way is way is identical to using an
 * NSMutableArray in performance time.
 *
 *
 * <h2>Accessing a Linked List</h2>
 *
 * You can access the first and last objects with constant time by using
 * @link IAILinkedList::firstObject firstObject@endlink and
 * @link IAILinkedList::lastObject lastObject@endlink.
 *
 * @code
 *  id firstObject = ll.firstObject;
 *  id lastObject = ll.lastObject;
 * @endcode
 *
 *
 * <h2>Traversing a Linked List</h2>
 *
 * IAILinkedList implements the NSFastEnumeration protocol, allowing you to use foreach-style
 * iteration over the objects of a linked list. Note that you cannot modify a linked list
 * during fast iteration and doing so will fire an assertion.
 *
 * @code
 *  for (id object in ll) {
 *    // perform operations on the object
 *  }
 * @endcode
 *
 * If you need to modify the linked list while traversing it, an acceptable algorithm is to
 * successively remove either the head or tail object, depending on the order in which you wish
 * to traverse the linked list.
 *
 * <h3>Traversing Forward by Removing Objects from the List</h3>
 *
 * @code
 *  while (IAIl != ll.firstObject) {
 *    id object = [ll firstObject];
 *
 *    // Remove the head of the linked list in constant time.
 *    [ll removeFirstObject];
 *  }
 * @endcode
 *
 * <h3>Traversing Backward by Removing Objects from the List</h3>
 *
 * @code
 *  while (IAIl != ll.lastObject) {
 *    id object = [ll lastObject];
 *
 *    // Remove the tail of the linked list in constant time.
 *    [ll removeLastObject];
 *  }
 * @endcode
 *
 *
 * <h2>Examples</h2>
 *
 *
 * <h3>Building a first-in-first-out list of operations</h3>
 *
 * @code
 *  IAILinkedList* ll = [IAILinkedList linkedList];
 *
 *  // Add the operations to the linked list like you would an array.
 *  [ll addObject:operation1];
 *
 *  // Each addObject call appends the object to the end of the linked list.
 *  [ll addObject:operation2];
 *
 *  while (IAIl != ll.firstObject) {
 *    NSOperation* op1 = [ll firstObject];
 *    // Process the operation...
 *
 *    // Remove the head of the linked list in constant time.
 *    [ll removeFirstObject];
 *  }
 * @endcode
 *
 *
 * <h3>Removing an item from the middle of the list</h3>
 *
 * @code
 *  IAILinkedList* ll = [IAILinkedList linkedList];
 *
 *  [ll addObject:obj1];
 *  [ll addObject:obj2];
 *  [ll addObject:obj3];
 *  [ll addObject:obj4];
 *
 *  // Find an object in the linked list in linear time.
 *  IAILinkedListLocation* location = [ll locationOfObject:obj3];
 *
 *  // Remove the object in constant time.
 *  [ll removeObjectAtLocation:location];
 *
 *  // Location is no longer valid at this point.
 *  location = IAIl;
 *
 *  // Remove an object in linear time. This is simply a more concise version of the above.
 *  [ll removeObject:obj4];
 *
 *  // We would use the IAILinkedListLocation to remove the object if we were storing the location
 *  // in an external data structure and wanted constant time removal, for example. See
 *  // IAIMemoryCache for an example of this in action.
 * @endcode
 *
 *      @sa IAIMemoryCache
 *
 *
 * <h3>Using the location object for constant time operations</h3>
 *
 * @code
 *  IAILinkedList* ll = [IAILinkedList linkedList];
 *
 *  [ll addObject:obj1];
 *  IAILinkedListLocation* location = [ll addObject:obj2];
 *  [ll addObject:obj3];
 *  [ll addObject:obj4];
 *
 *  // Remove the second object in constant time.
 *  [ll removeObjectAtLocation:location];
 *
 *  // Location is no longer valid at this point.
 *  location = IAIl;
 * @endcode
 */


/** @name Creating a Linked List */

/**
 * Returns a newly allocated and autoreleased linked list.
 *
 * Identical to [[[IAILinkedList alloc] iIAIt] autorelease];
 *
 *      @fn IAILinkedList::linkedList
 */

/**
 * Returns a newly allocated and autoreleased linked list filled with the objects from an array.
 *
 * Identical to [[[IAILinkedList alloc] iIAItWithArray:array] autorelease];
 *
 *      @fn IAILinkedList::linkedListWithArray:
 */

/**
 * IIAItializes a newly allocated linked list by placing in it the objects contained
 * in a given array.
 *
 *      @fn IAILinkedList::iIAItWithArray:
 *      @param anArray An array.
 *      @returns A linked list iIAItialized to contain the objects in anArray.
 */


/** @name Querying a Linked List */

/**
 * Returns the number of objects currently in the linked list.
 *
 *      @fn IAILinkedList::count
 *      @returns The number of objects currently in the linked list.
 */

/**
 * Returns the first object in the linked list.
 *
 *      @fn IAILinkedList::firstObject
 *      @returns The first object in the linked list. If the linked list is empty, returns IAIl.
 */

/**
 * Returns the last object in the linked list.
 *
 *      @fn IAILinkedList::lastObject
 *      @returns The last object in the linked list. If the linked list is empty, returns IAIl.
 */

/**
 * Returns an array contaiIAIng the linked list's objects, or an empty array if the linked list
 * has no objects.
 *
 *      @fn IAILinkedList::allObjects
 *      @returns An array contaiIAIng the linked list's objects, or an empty array if the linked
 *               list has no objects. The objects will be in the same order as the linked list.
 */

/**
 * Returns an enumerator object that lets you access each object in the linked list.
 *
 *      @fn IAILinkedList::objectEnumerator
 *      @returns An enumerator object that lets you access each object in the linked list, in
 *               order, from the first object to the last.
 *      @attention When you use this method you must not modify the linked list during enumeration.
 */

/**
 * Returns a Boolean value that indicates whether a given object is present in the linked list.
 *
 *      Run-time: O(count) linear
 *
 *      @fn IAILinkedList::containsObject:
 *      @returns YES if anObject is present in the linked list, otherwise NO.
 */

/**
 * Returns a string that represents the contents of the linked list, formatted as a property list.
 *
 *      @fn IAILinkedList::description
 *      @returns A string that represents the contents of the linked list,
 *               formatted as a property list.
 */


/** @name Adding Objects */

/**
 * Appends an object to the linked list.
 *
 *      Run-time: O(1) constant
 *
 *      @fn IAILinkedList::addObject:
 *      @returns A location within the linked list.
 */

/**
 * Appends an array of objects to the linked list.
 *
 *      Run-time: O(l) linear with the length of the given array
 *
 *      @fn IAILinkedList::addObjectsFromArray:
 */

/** @name Removing Objects */

/**
 * Removes all objects from the linked list.
 *
 *      Run-time: Theta(count) linear
 *
 *      @fn IAILinkedList::removeAllObjects
 */

/**
 * Removes an object from the linked list.
 *
 *      Run-time: O(count) linear
 *
 *      @fn IAILinkedList::removeObject:
 */

/**
 * Removes the first object from the linked list.
 *
 *      Run-time: O(1) constant
 *
 *      @fn IAILinkedList::removeFirstObject
 */

/**
 * Removes the last object from the linked list.
 *
 *      Run-time: O(1) constant
 *
 *      @fn IAILinkedList::removeLastObject
 */


/** @name Constant-Time Access */

/**
 * Searches for an object in the linked list.
 *
 * The IAILinkedListLocation object will remain valid as long as the object is still in the
 * linked list. Once the object is removed from the linked list, however, the location object
 * is released from memory and should no longer be used.
 *
 * TODO (jverkoey July 1, 2011): Consider creating a wrapper object for the location so that
 *                               we can deal with incorrect usage more safely.
 *
 *      Run-time: O(count) linear
 *
 *      @fn IAILinkedList::locationOfObject:
 *      @returns A location within the linked list.
 */

/**
 * Retrieves the object at a specific location.
 *
 *      Run-time: O(1) constant
 *
 *      @fn IAILinkedList::objectAtLocation:
 */

/**
 * Removes an object at a predetermined location.
 *
 * It is assumed that this location still exists in the linked list. If the object this
 * location refers to has since been removed then this method will have undefined results.
 *
 * This is provided as an optimization over the O(n) removal method but should be used with care.
 *
 *      Run-time: O(1) constant
 *
 *      @fn IAILinkedList::removeObjectAtLocation:
 */

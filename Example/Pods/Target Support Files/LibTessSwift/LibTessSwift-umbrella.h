#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "bucketalloc.h"
#import "dict.h"
#import "geom.h"
#import "mesh.h"
#import "objc-clang.h"
#import "priorityq.h"
#import "sweep.h"
#import "tess.h"
#import "tesselator.h"

FOUNDATION_EXPORT double LibTessSwiftVersionNumber;
FOUNDATION_EXPORT const unsigned char LibTessSwiftVersionString[];


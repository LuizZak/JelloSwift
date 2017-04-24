//
//  objc-clang.h
//  Pods
//
//  Created by Luiz Fernando Silva on 01/03/17.
//
//

#ifndef objc_clang_h
#define objc_clang_h

// For defining objective-c/clang specific features

#ifndef SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_EXTRA
#endif

#ifndef SWIFT_CLASS
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_CLASS_EXTRA
#endif

#ifndef SWIFT_CLASS_NAMED
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) \
__attribute__((swift_name(SWIFT_NAME))) SWIFT_CLASS_EXTRA
#endif

#ifndef NS_ASSUME_NONNULL_BEGIN
#   define NS_ASSUME_NONNULL_BEGIN
#endif
#ifndef NS_ASSUME_NONNULL_END
#   define NS_ASSUME_NONNULL_END
#endif

#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif

#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_EXTRA _name : _type
# if defined(__has_feature) && __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) SWIFT_ENUM(_type, _name)
# endif
#endif

#if defined(__has_attribute) && __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif

#endif /* objc_clang_h */

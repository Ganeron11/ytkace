#import <Foundation/Foundation.h>
#import <stddef.h>
#import <stdint.h>

NS_ASSUME_NONNULL_BEGIN

typedef uint32_t YTKACEByteKind;

typedef struct {
    const char * _Nullable pattern;
    YTKACEByteKind kind;
} YTKACEByteMarker;

typedef struct YTKACEByteMatcher YTKACEByteMatcher;

FOUNDATION_EXPORT YTKACEByteMatcher * _Nullable YTKACEByteMatcherCreate(
    const YTKACEByteMarker * _Nullable markers,
    size_t count);
FOUNDATION_EXPORT void YTKACEByteMatcherDestroy(
    YTKACEByteMatcher * _Nullable matcher);
FOUNDATION_EXPORT YTKACEByteKind YTKACEByteMatcherScan(
    const YTKACEByteMatcher * _Nullable matcher,
    const uint8_t * _Nullable bytes,
    size_t length,
    YTKACEByteKind wanted);
FOUNDATION_EXPORT YTKACEByteKind YTKACEByteMatcherScanData(
    const YTKACEByteMatcher * _Nullable matcher,
    NSData * _Nullable data,
    YTKACEByteKind wanted);

NS_ASSUME_NONNULL_END

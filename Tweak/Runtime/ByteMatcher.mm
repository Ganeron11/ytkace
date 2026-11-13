#import "ByteMatcher.h"

#import <stdlib.h>
#import <string.h>

typedef struct {
    int16_t next[128];
    int16_t fail;
    uint32_t mask;
} YTKACEByteTrieNode;

struct YTKACEByteMatcher {
    YTKACEByteTrieNode *nodes;
    int32_t used;
    int32_t capacity;
};

static void YTKACEByteTrieReset(YTKACEByteTrieNode *node) {
    for (NSUInteger byte = 0; byte < 128; byte++) {
        node->next[byte] = -1;
    }
    node->fail = 0;
    node->mask = 0;
}

static BOOL YTKACEByteTrieGrow(YTKACEByteMatcher *matcher) {
    if (matcher->capacity >= INT16_MAX) return NO;
    int32_t capacity = matcher->capacity * 2;
    if (capacity > INT16_MAX) capacity = INT16_MAX;
    YTKACEByteTrieNode *nodes = (YTKACEByteTrieNode *)realloc(
        matcher->nodes,
        (size_t)capacity * sizeof(YTKACEByteTrieNode));
    if (nodes == NULL) return NO;
    for (int32_t index = matcher->capacity; index < capacity; index++) {
        YTKACEByteTrieReset(&nodes[index]);
    }
    matcher->nodes = nodes;
    matcher->capacity = capacity;
    return YES;
}

YTKACEByteMatcher * _Nullable YTKACEByteMatcherCreate(
    const YTKACEByteMarker * _Nullable markers,
    size_t count) {
    if (markers == NULL || count == 0) return NULL;

    YTKACEByteMatcher *matcher =
        (YTKACEByteMatcher *)calloc(1, sizeof(YTKACEByteMatcher));
    if (matcher == NULL) return NULL;

    matcher->capacity = 64;
    matcher->nodes = (YTKACEByteTrieNode *)malloc(
        (size_t)matcher->capacity * sizeof(YTKACEByteTrieNode));
    if (matcher->nodes == NULL) {
        free(matcher);
        return NULL;
    }
    for (int32_t index = 0; index < matcher->capacity; index++) {
        YTKACEByteTrieReset(&matcher->nodes[index]);
    }
    matcher->used = 1;

    BOOL inserted = YES;
    for (size_t markerIndex = 0; markerIndex < count; markerIndex++) {
        const char *pattern = markers[markerIndex].pattern;
        YTKACEByteKind kind = markers[markerIndex].kind;
        if (pattern == NULL || pattern[0] == '\0' || kind == 0) continue;

        size_t length = strlen(pattern);
        BOOL ascii = YES;
        for (size_t index = 0; index < length; index++) {
            if ((unsigned char)pattern[index] >= 128) {
                ascii = NO;
                break;
            }
        }
        if (!ascii) continue;

        int32_t state = 0;
        for (size_t index = 0; index < length; index++) {
            uint8_t byte = (uint8_t)pattern[index];
            int16_t next = matcher->nodes[state].next[byte];
            if (next < 0) {
                if (matcher->used >= matcher->capacity &&
                    !YTKACEByteTrieGrow(matcher)) {
                    inserted = NO;
                    break;
                }
                int32_t node = matcher->used++;
                YTKACEByteTrieReset(&matcher->nodes[node]);
                matcher->nodes[state].next[byte] = (int16_t)node;
                next = (int16_t)node;
            }
            state = next;
        }
        if (!inserted) break;
        matcher->nodes[state].mask |= kind;
    }

    if (!inserted) {
        YTKACEByteMatcherDestroy(matcher);
        return NULL;
    }

    int16_t *queue = (int16_t *)malloc(
        (size_t)matcher->used * sizeof(int16_t));
    if (queue == NULL) {
        YTKACEByteMatcherDestroy(matcher);
        return NULL;
    }

    int32_t head = 0;
    int32_t tail = 0;
    for (NSUInteger byte = 0; byte < 128; byte++) {
        int16_t next = matcher->nodes[0].next[byte];
        if (next < 0) {
            matcher->nodes[0].next[byte] = 0;
        } else {
            queue[tail++] = next;
        }
    }
    while (head < tail) {
        int16_t state = queue[head++];
        int16_t failure = matcher->nodes[state].fail;
        matcher->nodes[state].mask |= matcher->nodes[failure].mask;
        for (NSUInteger byte = 0; byte < 128; byte++) {
            int16_t next = matcher->nodes[state].next[byte];
            if (next < 0) {
                matcher->nodes[state].next[byte] =
                    matcher->nodes[failure].next[byte];
            } else {
                matcher->nodes[next].fail =
                    matcher->nodes[failure].next[byte];
                queue[tail++] = next;
            }
        }
    }
    free(queue);

    if (matcher->used < matcher->capacity) {
        YTKACEByteTrieNode *nodes = (YTKACEByteTrieNode *)realloc(
            matcher->nodes,
            (size_t)matcher->used * sizeof(YTKACEByteTrieNode));
        if (nodes != NULL) {
            matcher->nodes = nodes;
            matcher->capacity = matcher->used;
        }
    }
    return matcher;
}

void YTKACEByteMatcherDestroy(YTKACEByteMatcher * _Nullable matcher) {
    if (matcher == NULL) return;
    free(matcher->nodes);
    free(matcher);
}

YTKACEByteKind YTKACEByteMatcherScan(
    const YTKACEByteMatcher * _Nullable matcher,
    const uint8_t * _Nullable bytes,
    size_t length,
    YTKACEByteKind wanted) {
    if (matcher == NULL || matcher->nodes == NULL ||
        bytes == NULL || length == 0 || wanted == 0) {
        return 0;
    }

    const YTKACEByteTrieNode *nodes = matcher->nodes;
    int32_t state = 0;
    YTKACEByteKind found = 0;
    for (size_t index = 0; index < length; index++) {
        uint8_t byte = bytes[index];
        if (byte >= 128) {
            state = 0;
            continue;
        }
        int16_t next = nodes[state].next[byte];
        state = next < 0 ? 0 : next;
        found |= nodes[state].mask;
        if ((found & wanted) == wanted) break;
    }
    return found;
}

YTKACEByteKind YTKACEByteMatcherScanData(
    const YTKACEByteMatcher * _Nullable matcher,
    NSData * _Nullable data,
    YTKACEByteKind wanted) {
    if (data == nil) return 0;
    return YTKACEByteMatcherScan(
        matcher,
        (const uint8_t *)data.bytes,
        data.length,
        wanted);
}

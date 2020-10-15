#import "RNTPTDocumentViewModule.h"

#import "RNTPTDocumentViewManager.h"

#import <React/RCTLog.h>
#import <PDFNet/PDFNet.h>

@implementation RNTPTDocumentViewModule

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE(DocumentViewManager) // JS-name

- (RNTPTDocumentViewManager *)documentViewManager
{
    return [self.bridge moduleForClass:[RNTPTDocumentViewManager class]];
}

- (NSError *)errorFromException:(NSException *)exception
{
    return [NSError errorWithDomain:@"com.pdftron.react-native" code:0 userInfo:
            @{
              NSLocalizedDescriptionKey: exception.name,
              NSLocalizedFailureReasonErrorKey: exception.reason,
              }];
}

#pragma mark - Methods

RCT_REMAP_METHOD(setToolMode,
                 setToolModeForDocumentViewTag:(nonnull NSNumber *)tag
                 toolMode:(NSString *)toolMode)
{
    [[self documentViewManager] setToolModeForDocumentViewTag:tag toolMode:toolMode];
}

RCT_REMAP_METHOD(commitTool,
                 commitToolForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        BOOL committed = [[self documentViewManager] commitToolForDocumentViewTag:tag];
        resolve(@(committed));
    }
    @catch (NSException *exception) {
        reject(@"commit_tool", @"Failed to commit tool", [self errorFromException:exception]);
    }
}

#pragma mark - Methods (w/ promises)

RCT_REMAP_METHOD(getDocumentPath,
                 getDocumentPathForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSString *path = [[self documentViewManager] getDocumentPathForDocumentViewTag:tag];
        resolve(path);
    }
    @catch (NSException *exception) {
        reject(@"export_failed", @"Failed to get document path", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(getPageCount,
                 getPageCountForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        int pageCount = [[self documentViewManager] getPageCountForDocumentViewTag:tag];
        resolve(@(pageCount));
    }
    @catch (NSException *exception) {
        reject(@"get_failed", @"Failed to get page count", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(importBookmarkJson,
                 importBookmarkJsonForDocumentViewTag:(nonnull NSNumber *)tag
                 bookmarkJson:(NSString *)bookmarkJson
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] importBookmarkJsonForDocumentViewTag:tag bookmarkJson:bookmarkJson];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"import_failed", @"Failed to import bookmark json", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(exportAnnotations,
                 exportAnnotationsForDocumentViewTag:(nonnull NSNumber *)tag
                 options:(NSDictionary *)options
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSString *xfdf = [[self documentViewManager] exportAnnotationsForDocumentViewTag:tag
                                                                                 options:options];
        resolve(xfdf);
    }
    @catch (NSException *exception) {
        reject(@"export_failed", @"Failed to export annotations", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(importAnnotations,
                 importAnnotationsForDocumentViewTag:(nonnull NSNumber *)tag
                 xfdf:(NSString *)xfdf
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] importAnnotationsForDocumentViewTag:tag xfdf:xfdf];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"import_failed", @"Failed to import annotations", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(flattenAnnotations,
                 flattenAnnotationsForDocumentViewTag:(nonnull NSNumber *)tag
                 formsOnly:(BOOL)formsOnly
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] flattenAnnotationsForDocumentViewTag:tag formsOnly:formsOnly];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"flatten_failed", @"Failed to flatten annotations", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(deleteAnnotations,
                 deleteAnnotationsForDocumentViewTag:(nonnull NSNumber *)tag
                 annotations:(NSArray *)annotations
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] deleteAnnotationsForDocumentViewTag:tag annotations:annotations];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"delete_failed", @"Failed to delete annotations", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(saveDocument,
                 saveDocumentForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] saveDocumentForDocumentViewTag:tag completionHandler:^(NSString * _Nullable filePath) {
            if (filePath) {
                resolve(filePath);
            } else {
                reject(@"save_failed", @"Failed to save document", nil);
            }
        }];
    }
    @catch (NSException *exception) {
        reject(@"save_failed", @"Failed to save document", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(setFlagForFields,
                 setFlagForFieldsForDocumentViewTag:(nonnull NSNumber *)tag
                 fields:(NSArray<NSString *> *)fields
                 flag:(NSInteger)flag
                 value:(BOOL)value
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] setFlagForFieldsForDocumentViewTag:tag forFields:fields setFlag:(PTFieldFlag)flag toValue:value];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"set_flag_for_fields", @"Failed to set flag on fields", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(setValuesForFields,
                 setValuesForFieldsForDocumentViewTag:(nonnull NSNumber *)tag
                 map:(NSDictionary<NSString *, id> *)map
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] setValuesForFieldsForDocumentViewTag:tag map:map];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"set_value_for_fields", @"Failed to set value on fields", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(setFlagsForAnnotations,
                 setFlagsForAnnotationsForDocumentViewTag:(nonnull NSNumber *)tag
                 annotationFlagList:(NSArray *)annotationFlagList
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] setFlagsForAnnotationsForDocumentViewTag:tag annotationFlagList:annotationFlagList];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"set_flag_for_annotations", @"Failed to set flag on annotations", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(selectAnnotation,
                 selectAnnotationForDocumentViewTag:(nonnull NSNumber *)tag
                 annotationId:(NSString *)annotationId
                 pageNumber:(NSInteger)pageNumber
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] selectAnnotationForDocumentViewTag:tag annotationId:annotationId pageNumber:pageNumber];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"select_annotation", @"Failed to select annotation", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(setPropertiesForAnnotation,
                 setPropertiesForAnnotationForDocumentViewTag: (nonnull NSNumber *)tag
                 annotationId:(NSString *)annotationId
                 pageNumber:(NSInteger)pageNumber
                 propertyMap:(NSDictionary *)propertyMap
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] setPropertiesForAnnotation:tag annotationId:annotationId pageNumber:pageNumber propertyMap:propertyMap];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"set_property_for_annotation", @"Failed to set property for annotation", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(getPageCropBox,
                 getPageCropBoxForDocumentViewTag: (nonnull NSNumber *)tag
                 pageNumber:(NSInteger)pageNumber
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSDictionary<NSString *, NSNumber *> *cropBox = [[self documentViewManager] getPageCropBoxForDocumentViewTag:tag pageNumber:pageNumber];
        resolve(cropBox);
    }
    @catch (NSException *exception) {
        reject(@"get_page_crop_box", @"Failed to get page cropbox", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(setCurrentPage,
                 setCurrentPageforDocumentViewTag: (nonnull NSNumber *) tag
                 pageNumber:(NSInteger)pageNumber
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        bool setResult = [[self documentViewManager] setCurrentPageForDocumentViewTag:tag pageNumber:pageNumber];
        resolve([NSNumber numberWithBool:setResult]);
    }
    @catch (NSException *exception) {
        reject(@"set_current_page", @"Failed to set current page", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(closeAllTabs,
                 closeAllTabsForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] closeAllTabsForDocumentViewTag:tag];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"export_failed", @"Failed to close all tabs", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(getZoom,
                 getZoomForDocumentViewTag: (nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        double zoom = [[self documentViewManager] getZoom:tag];
        resolve([NSNumber numberWithDouble:zoom]);
    }
    @catch (NSException *exception) {
        reject(@"get_zoom", @"Failed to get zoom", [self errorFromException:exception]);
    }
}

#pragma mark - Collaboration

RCT_REMAP_METHOD(importAnnotationCommand,
                 importAnnotationCommandForDocumentViewTag:(nonnull NSNumber *)tag
                 xfdf:(NSString *)xfdfCommand
                 initialLoad:(BOOL)initialLoad
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] importAnnotationCommandForDocumentViewTag:tag xfdfCommand:xfdfCommand initialLoad:initialLoad];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"import_failed", @"Failed to import annotation command", [self errorFromException:exception]);
    }
}





#pragma mark - Custom CAT

RCT_REMAP_METHOD(search,
                 searchForDocumentViewTag:(nonnull NSNumber *)tag
                 searchString:(NSString *)searchString
                 case:(BOOL)isCase
                 whole:(BOOL)isWhole
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSArray *results = [[self documentViewManager] searchForDocumentViewTag:tag search:searchString case:isCase whole:isWhole];
        resolve(results);
    }
    @catch (NSException *exception) {
        reject(@"search_failed", @"SEARCH FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(clearSearch,
                 clearSearchForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] clearSearchForDocumentViewTag:tag];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"clearSearch_Failed", @"CLEAR SEARCH FAILED MISERABLY", [self errorFromException:exception]);
    }
}



RCT_REMAP_METHOD(findTextIOS,
                 findTextForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] findTextForDocumentViewTag:tag];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"findText_failed", @"FIND TEXT FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(toggleSlider,
                 toggleSliderForDocumentViewTag:(nonnull NSNumber *)tag
                 toggle:(BOOL)toggle
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] toggleSliderForDocumentViewTag:tag toggleSlider:toggle];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"rotate_failed", @"TOGGLE SLIDER PAGE FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(getDimensions,
                 getDimensionsForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSDictionary *dimensions = [[self documentViewManager] getDimensionsForDocumentViewTag:tag];
        resolve(dimensions);
    }
    @catch (NSException *exception) {
        reject(@"dimensions_failed", @"DIMENSIONS FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(jumpTo,
                 jumpToForDocumentViewTag:(nonnull NSNumber *)tag
                 page_num:(int)page_num
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] jumpToForDocumentViewTag:tag jumpTo:page_num];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"setPageNum_failed", @"SET CURRENT PAGE FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(appendSchoolLogo,
                 appendSchoolLogoForDocumentViewTag:(nonnull NSNumber *)tag
                 base64String:(NSString *)base64String
                 duplex:(BOOL)isDuplex
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] appendSchoolLogoForDocumentViewTag:tag appendSchoolLogo:base64String duplex:isDuplex];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"addSchoolLogo_failed", @"ADD SCHOOL LOGO FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(rotate,
                 rotateForDocumentViewTag:(nonnull NSNumber *)tag
                 ccw:(BOOL)ccw
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] rotateForDocumentViewTag:tag rotate:ccw];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"rotate_failed", @"ROTATE PAGE FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(getOutline,
                 getOutlineForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSArray *outline = [[self documentViewManager] getOutlineForDocumentViewTag:tag];
        resolve(outline);
    }
    @catch (NSException *exception) {
        reject(@"outline_failed", @"GET OUTLINE FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(addBookmark,
                 addBookmarkForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] addBookmarkForDocumentViewTag:tag];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"bookmark_failed", @"ADD BOOKMARK FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(getThumbnail,
                 getThumbnailForDocumentViewTag:(nonnull NSNumber *)tag
                 pageNumber:(int)pageNumber
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] getThumbnailForDocumentViewTag:tag getThumbnail:pageNumber completionHandler:^(NSString * _Nullable base64String) {
               if (base64String) {
                   resolve(base64String);
               } else {
                   reject(@"thumbnail_failed", @"Failed to get thumbnail", nil);
               }
           }];
    }
    @catch (NSException *exception) {
        reject(@"thumbnail_failed", @"THUMBNAILS FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(abortGetThumbnail,
                 abortGetThumbnailForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] abortGetThumbnailForDocumentViewTag:tag];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"abort_get_thumb", @"ABORT THUMBNAILS FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(currentPage,
                 currentPageForDocumentViewTag:(nonnull NSNumber *)tag
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        
        NSNumber *page = [NSNumber numberWithInt:[[self documentViewManager] currentPageForDocumentViewTag:tag]];
        resolve(page);
    }
    @catch (NSException *exception) {
        reject(@"rotate_failed", @"CURRENT PAGE FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(changeBackground,
                 changeBackgroundForDocumentViewTag:(nonnull NSNumber *)tag
                 red:(int)r
                 green:(int)g
                 blue:(int)b
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] changeBackgroundForDocumentViewTag:tag changeBackground:r green:g blue:b];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"changeBackground_failed", @"CHANGE BACKRGOUND FAILED MISERABLY", [self errorFromException:exception]);
    }
}

RCT_REMAP_METHOD(setContinuous,
                 setContinuousForDocumentViewTag:(nonnull NSNumber *)tag
                 toggle:(int)toggle
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        [[self documentViewManager] setContinuousForDocumentViewTag:tag setContinuous:toggle];
        resolve(nil);
    }
    @catch (NSException *exception) {
        reject(@"changeBackground_failed", @"CHANGE BACKRGOUND FAILED MISERABLY", [self errorFromException:exception]);
    }
}



@end

//
//  RNTPTDocumentViewManager.h
//  RNPdftron
//
//  Copyright © 2018 PDFTron. All rights reserved.
//

#import "RNTPTDocumentView.h"

#import <React/RCTViewManager.h>

@interface RNTPTDocumentViewManager : RCTViewManager <RNTPTDocumentViewDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, RNTPTDocumentView *> *documentViews;

- (void)setToolModeForDocumentViewTag:(NSNumber *)tag toolMode:(NSString *)toolMode;

- (BOOL)commitToolForDocumentViewTag:(NSNumber *)tag;

- (NSString *)getDocumentPathForDocumentViewTag:(NSNumber *)tag;

- (int)getPageCountForDocumentViewTag:(NSNumber *)tag;

- (void)importBookmarkJsonForDocumentViewTag:(NSNumber *)tag bookmarkJson:(NSString *)bookmarkJson;

- (NSString *)exportAnnotationsForDocumentViewTag:(NSNumber *)tag options:(NSDictionary *)options;
- (void)importAnnotationsForDocumentViewTag:(NSNumber *)tag xfdf:(NSString *)xfdfString;

- (void)flattenAnnotationsForDocumentViewTag:(NSNumber *)tag formsOnly:(BOOL)formsOnly;

- (void)deleteAnnotationsForDocumentViewTag:(NSNumber *)tag annotations:(NSArray *)annotations;

- (void)saveDocumentForDocumentViewTag:(NSNumber *)tag completionHandler:(void (^)(NSString * _Nullable filePath))completionHandler;

- (void)setFlagForFieldsForDocumentViewTag:(NSNumber *)tag forFields:(NSArray<NSString *> *)fields setFlag:(PTFieldFlag)flag toValue:(BOOL)value;

- (void)setValuesForFieldsForDocumentViewTag:(NSNumber *)tag map:(NSDictionary<NSString *, id> *)map;

- (void)setFlagsForAnnotationsForDocumentViewTag:(NSNumber*) tag annotationFlagList:(NSArray *)annotationFlagList;

- (void)selectAnnotationForDocumentViewTag:(NSNumber *)tag annotationId:(NSString *)annotationId pageNumber:(NSInteger)pageNumber;

- (void)setPropertiesForAnnotation:(NSNumber *)tag annotationId:(NSString *)annotationId pageNumber:(NSInteger)pageNumber propertyMap:(NSDictionary *)propertyMap;

- (NSDictionary<NSString *, NSNumber *> *)getPageCropBoxForDocumentViewTag:(NSNumber *)tag pageNumber:(NSInteger)pageNumber;

- (BOOL)setCurrentPageForDocumentViewTag:(NSNumber *)tag pageNumber:(NSInteger)pageNumber;

- (void)closeAllTabsForDocumentViewTag:(NSNumber *)tag;

- (double)getZoom:(NSNumber *)tag;
- (void)importAnnotationCommandForDocumentViewTag:(NSNumber *)tag xfdfCommand:(NSString *)xfdfCommand initialLoad:(BOOL)initialLoad;



#pragma mark - Custom CAT

- (NSArray<NSDictionary<NSString *, NSString *> *> *)searchForDocumentViewTag:(NSNumber *)tag search:(NSString *)searchString case:(BOOL)isCase whole:(BOOL)isWhole;

- (void)clearSearchForDocumentViewTag:(NSNumber *)tag;

- (NSDictionary<NSString *, NSNumber *> *)getDimensionsForDocumentViewTag:(NSNumber *)tag;

- (void)jumpToForDocumentViewTag:(NSNumber *)tag jumpTo:(int)page_num;

- (void)appendSchoolLogoForDocumentViewTag:(NSNumber *)tag appendSchoolLogo:(NSString *)base64String duplex:(BOOL)isDuplex;

- (void)rotateForDocumentViewTag:(NSNumber *)tag rotate:(BOOL)ccw;

- (void)addBookmarkForDocumentViewTag:(NSNumber *)tag;

- (void)findTextForDocumentViewTag:(NSNumber *)tag;

- (void)showSettingsForDocumentViewTag:(NSNumber *)tag;

- (void)toggleSliderForDocumentViewTag:(NSNumber *)tag toggleSlider:(BOOL)toggle;

- (void)getThumbnailForDocumentViewTag:(NSNumber *)tag getThumbnail:(int)pageNumber completionHandler:(void (^)(NSString * _Nullable baser64String))completionHandler;

- (NSArray<NSDictionary<NSString *, id> *> *)getOutlineForDocumentViewTag:(NSNumber *)tag;

- (int)currentPageForDocumentViewTag:(NSNumber *)tag;

- (void)changeBackgroundForDocumentViewTag:(NSNumber *)tag changeBackground:(int)r green:(int)g blue:(int)b;

- (void)setColorModeForDocumentViewTag:(NSNumber *)tag setColorMode:(NSString *)mode;

- (void)setContinuousForDocumentViewTag:(NSNumber *)tag setContinuous:(BOOL)toggle;

@end

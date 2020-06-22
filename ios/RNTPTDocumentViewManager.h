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

- (int)getPageCountForDocumentViewTag:(NSNumber *)tag;

- (NSString *)exportAnnotationsForDocumentViewTag:(NSNumber *)tag options:(NSDictionary *)options;
- (void)importAnnotationsForDocumentViewTag:(NSNumber *)tag xfdf:(NSString *)xfdfString;

- (void)flattenAnnotationsForDocumentViewTag:(NSNumber *)tag formsOnly:(BOOL)formsOnly;

- (void)deleteAnnotationsForDocumentViewTag:(NSNumber *)tag annotations:(NSArray *)annotations;

- (void)saveDocumentForDocumentViewTag:(NSNumber *)tag completionHandler:(void (^)(NSString * _Nullable filePath))completionHandler;

- (void)setFlagForFieldsForDocumentViewTag:(NSNumber *)tag forFields:(NSArray<NSString *> *)fields setFlag:(PTFieldFlag)flag toValue:(BOOL)value;

- (void)setValueForFieldsForDocumentViewTag:(NSNumber *)tag map:(NSDictionary<NSString *, id> *)map;

- (void)importAnnotationCommandForDocumentViewTag:(NSNumber *)tag xfdfCommand:(NSString *)xfdfCommand initialLoad:(BOOL)initialLoad;




// Custom Search
- (NSArray<NSDictionary<NSString *, NSString *> *> *)searchForDocumentViewTag:(NSNumber *)tag search:(NSString *)searchString;

// Get Document Dimensions
- (NSDictionary<NSString *, NSNumber *> *)getDimensionsForDocumentViewTag:(NSNumber *)tag;

// Jump to Page
- (void)jumpToForDocumentViewTag:(NSNumber *)tag jumpTo:(int)page_num;

// SchoolLogo
- (void)appendSchoolLogoForDocumentViewTag:(NSNumber *)tag appendSchoolLogo:(NSString *)base64String duplex:(BOOL)isDuplex;

// ROtate Manager
- (void)rotateForDocumentViewTag:(NSNumber *)tag rotate:(BOOL)ccw;




@end

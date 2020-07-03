#import "RNTPTDocumentView.h"

#import "RNTPTDocumentViewController.h"
#import "RNTPTCollaborationDocumentViewController.h"

#include <objc/runtime.h>

static BOOL RNTPT_addMethod(Class cls, SEL selector, void (^block)(id))
{
    const IMP implementation = imp_implementationWithBlock(block);
    
    const BOOL added = class_addMethod(cls, selector, implementation, "v@:");
    if (!added) {
        imp_removeBlock(implementation);
        return NO;
    }
    
    return YES;
}

NS_ASSUME_NONNULL_BEGIN

@interface RNTPTDocumentView () <RNTPTDocumentViewControllerDelegate, PTCollaborationServerCommunication>

@property (nonatomic, nullable) PTDocumentViewController *documentViewController;

@property (nonatomic, readonly, nullable) PTPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, readonly, nullable) PTToolManager *toolManager;

@property (nonatomic, readonly, nullable) RNTPTDocumentViewController *rnt_documentViewController;

@property (nonatomic, readonly, nullable) RNTPTCollaborationDocumentViewController *rnt_collabDocumentViewController;

@property (nonatomic, assign) BOOL needsCustomHeadersUpdate;

@property (nonatomic, strong, nullable) NSArray<NSNumber*>* hideAnnotMenuToolsAnnotTypes;

@end

NS_ASSUME_NONNULL_END

@implementation RNTPTDocumentView

- (void)RNTPTDocumentView_commonInit
{
    _topToolbarEnabled = YES;
    _bottomToolbarEnabled = YES;
    
    _pageIndicatorEnabled = YES;
    _pageIndicatorShowsOnPageChange = YES;
    _pageIndicatorShowsWithControls = YES;
    
    _autoSaveEnabled = YES;
    
    _pageChangeOnTap = NO;
    _thumbnailViewEditingEnabled = YES;
    _selectAnnotationAfterCreation = YES;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self RNTPTDocumentView_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self RNTPTDocumentView_commonInit];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)didMoveToWindow
{
    if (self.window) {
        if ([self.delegate respondsToSelector:@selector(documentViewAttachedToWindow:)]) {
            [self.delegate documentViewAttachedToWindow:self];
        }
        
        [self loadDocumentViewController];
    } else {
        if ([self.delegate respondsToSelector:@selector(documentViewDetachedFromWindow:)]) {
            [self.delegate documentViewDetachedFromWindow:self];
        }
    }
}

- (void)didMoveToSuperview
{
    if (!self.superview) {
        [self unloadDocumentViewController];
    }
}

#pragma mark - DocumentViewController

- (RNTPTDocumentViewController *)rnt_documentViewController
{
    if ([self.documentViewController isKindOfClass:[RNTPTDocumentViewController class]]) {
        return (RNTPTDocumentViewController *)self.documentViewController;
    }
    return nil;
}

- (RNTPTCollaborationDocumentViewController *)rnt_collabDocumentViewController
{
    if ([self.documentViewController isKindOfClass:[RNTPTCollaborationDocumentViewController class]]) {
        return (RNTPTCollaborationDocumentViewController *)self.documentViewController;
    }
    return nil;
}

#pragma mark - Convenience

- (nullable PTPDFViewCtrl *)pdfViewCtrl
{
    return self.documentViewController.pdfViewCtrl;
}

- (nullable PTToolManager *)toolManager
{
    return self.documentViewController.toolManager;
}

#pragma mark - Document Openining

-(void)openDocument
{
    if( self.documentViewController == Nil )
    {
        return;
    }
    
    if (![self isBase64String]) {
        // Open a file URL.
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:self.document withExtension:@"pdf"];
        if ([self.document containsString:@"://"]) {
            fileURL = [NSURL URLWithString:self.document];
        } else if ([self.document hasPrefix:@"/"]) {
            fileURL = [NSURL fileURLWithPath:self.document];
        }
        
        [self.documentViewController openDocumentWithURL:fileURL
                                                password:self.password];
        
        [self applyLayoutMode];
    } else {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:self.document options:0];
        
        PTPDFDoc *doc = nil;
        @try {
            doc = [[PTPDFDoc alloc] initWithBuf:data buf_size:data.length];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
            return;
        }
        
        [self.documentViewController openDocumentWithPDFDoc:doc];
        
        [self applyLayoutMode];
    }
    
    
    // Adjustment custom Init function for better clearity
    [self customInit];
}

-(void)setDocument:(NSString *)document
{
    _document = document;
    [self openDocument];

}

#pragma mark - DocumentViewController loading

- (void)loadDocumentViewController
{
    if (!self.documentViewController) {
        if ([self isCollabEnabled]) {
            self.documentViewController = [[RNTPTCollaborationDocumentViewController alloc] initWithCollaborationService:self];
        } else {
            self.documentViewController = [[RNTPTDocumentViewController alloc] init];
        }
        self.documentViewController.delegate = self;
        
        [self applyViewerSettings];
    }
    
    [self registerForDocumentViewControllerNotifications];
    [self registerForPDFViewCtrlNotifications];
    
    // Check if document view controller has already been added to a navigation controller.
    if (self.documentViewController.navigationController) {
        return;
    }
    
    // Find the view's containing UIViewController.
    UIViewController *parentController = [self findParentViewController];
    if (parentController == nil || self.window == nil) {
        return;
    }
    
    if (self.showNavButton) {
        UIImage *navImage = [UIImage imageNamed:self.navButtonPath];
        UIBarButtonItem *navButton = [[UIBarButtonItem alloc] initWithImage:navImage
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(navButtonClicked)];
        self.documentViewController.navigationItem.leftBarButtonItem = navButton;
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.documentViewController];
    
    const BOOL translucent = self.documentViewController.hidesControlsOnTap;
    navigationController.navigationBar.translucent = translucent;
    self.documentViewController.thumbnailSliderController.toolbar.translucent = translucent;
    
    UIView *controllerView = navigationController.view;
    
    // View controller containment.
    [parentController addChildViewController:navigationController];
    
    controllerView.frame = self.bounds;
    controllerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self addSubview:controllerView];
    
    [navigationController didMoveToParentViewController:parentController];
    
    navigationController.navigationBarHidden = !self.topToolbarEnabled;
    
    [self openDocument];
}

- (void)unloadDocumentViewController
{
    [self deregisterForPDFViewCtrlNotifications];
    
    UINavigationController *navigationController = self.documentViewController.navigationController;
    if (navigationController) {
        // Clear navigation stack (PTDocumentViewController).
        navigationController.viewControllers = @[];
        
        // Remove from parent view controller.
        [navigationController willMoveToParentViewController:nil];
        [navigationController.view removeFromSuperview];
        [navigationController removeFromParentViewController];
    }
}

#pragma mark Notifications

- (void)registerForDocumentViewControllerNotifications
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(documentViewControllerDidOpenDocumentWithNotification:)
                   name:PTDocumentViewControllerDidOpenDocumentNotification
                 object:self.documentViewController];
}

- (void)registerForPDFViewCtrlNotifications
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(pdfViewCtrlDidChangePageWithNotification:)
                   name:PTPDFViewCtrlPageDidChangeNotification
                 object:self.documentViewController.pdfViewCtrl];
    
    [center addObserver:self
               selector:@selector(toolManagerDidAddAnnotationWithNotification:)
                   name:PTToolManagerAnnotationAddedNotification
                 object:self.documentViewController.toolManager];
    
    [center addObserver:self
               selector:@selector(toolManagerDidModifyAnnotationWithNotification:)
                   name:PTToolManagerAnnotationModifiedNotification
                 object:self.documentViewController.toolManager];
    
    [center addObserver:self
               selector:@selector(toolManagerDidRemoveAnnotationWithNotification:)
                   name:PTToolManagerAnnotationRemovedNotification
                 object:self.documentViewController.toolManager];
}

- (void)deregisterForPDFViewCtrlNotifications
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center removeObserver:self
                      name:PTPDFViewCtrlPageDidChangeNotification
                    object:self.documentViewController.pdfViewCtrl];
    
    [center removeObserver:self
                      name:PTToolManagerAnnotationAddedNotification
                    object:self.documentViewController.toolManager];
    
    [center removeObserver:self
                      name:PTToolManagerAnnotationModifiedNotification
                    object:self.documentViewController.toolManager];
    
    [center removeObserver:self
                      name:PTToolManagerAnnotationRemovedNotification
                    object:self.documentViewController.toolManager];
}

#pragma mark - Disabling elements

- (int)getPageCount
{
    return self.documentViewController.pdfViewCtrl.pageCount;
}

- (void)setDisabledElements:(NSArray<NSString *> *)disabledElements
{
    _disabledElements = [disabledElements copy];
    
    if (self.documentViewController) {
        [self disableElementsInternal:disabledElements];
    }
}

- (void)disableElementsInternal:(NSArray<NSString*> *)disabledElements
{
    typedef void (^HideElementBlock)(void);
    
    NSDictionary *hideElementActions = @{
        @"toolsButton":
            ^{
                self.documentViewController.annotationToolbarButtonHidden = YES;
            },
        @"searchButton":
            ^{
                self.documentViewController.searchButtonHidden = YES;
            },
        @"shareButton":
            ^{
                self.documentViewController.shareButtonHidden = YES;
            },
        @"viewControlsButton":
            ^{
                self.documentViewController.viewerSettingsButtonHidden = YES;
            },
        @"thumbnailsButton":
            ^{
                self.documentViewController.thumbnailBrowserButtonHidden = YES;
            },
        @"listsButton":
            ^{
                self.documentViewController.navigationListsButtonHidden = YES;
            },
        @"moreItemsButton":
            ^{
                self.documentViewController.moreItemsButtonHidden = YES;
            },
        
        @"thumbnailSlider":
            ^{
                self.documentViewController.thumbnailSliderHidden = YES;
            },
        
        @"outlineListButton":
            ^{
                self.documentViewController.outlineListHidden = YES;
            },
        @"annotationListButton":
            ^{
                self.documentViewController.annotationListHidden = YES;
            },
        @"userBookmarkListButton":
            ^{
                self.documentViewController.bookmarkListHidden = YES;
            },
        @"reflowButton":
            ^{
                self.documentViewController.readerModeButtonHidden = YES;
            },
    };
    
    for (NSObject *item in disabledElements) {
        if ([item isKindOfClass:[NSString class]]) {
            HideElementBlock block = hideElementActions[item];
            if (block) {
                block();
            }
        }
    }
    
    // Disable the elements' corresponding tools/annotation types creation.
    [self setToolsPermission:disabledElements toValue:NO];
}

#pragma mark - Disabled tools

- (void)setDisabledTools:(NSArray<NSString *> *)disabledTools
{
    _disabledTools = [disabledTools copy];
    
    if (self.documentViewController) {
        [self setToolsPermission:disabledTools toValue:NO];
    }
}

- (void)setToolsPermission:(NSArray<NSString *> *)stringsArray toValue:(BOOL)value
{
    // TODO: AnnotationCreateDistanceMeasurement
    // AnnotationCreatePerimeterMeasurement
    // AnnotationCreateAreaMeasurement
    
    for (NSObject *item in stringsArray) {
        if ([item isKindOfClass:[NSString class]]) {
            NSString *string = (NSString *)item;
            
            if ([string isEqualToString:@"AnnotationEdit"]) {
                // multi-select not implemented
            }
            else if ([string isEqualToString:@"AnnotationCreateSticky"] ||
                     [string isEqualToString:@"stickyToolButton"]) {
                self.toolManager.textAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateFreeHand"] ||
                     [string isEqualToString:@"freeHandToolButton"]) {
                self.toolManager.inkAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"TextSelect"]) {
                self.toolManager.textSelectionEnabled = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateTextHighlight"] ||
                     [string isEqualToString:@"highlightToolButton"]) {
                self.toolManager.highlightAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateTextUnderline"] ||
                     [string isEqualToString:@"underlineToolButton"]) {
                self.toolManager.underlineAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateTextSquiggly"] ||
                     [string isEqualToString:@"squigglyToolButton"]) {
                self.toolManager.squigglyAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateTextStrikeout"] ||
                     [string isEqualToString:@"strikeoutToolButton"]) {
                self.toolManager.strikeOutAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateFreeText"] ||
                     [string isEqualToString:@"freeTextToolButton"]) {
                self.toolManager.freeTextAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateCallout"] ||
                     [string isEqualToString:@"calloutToolButton"]) {
                // not supported
            }
            else if ([string isEqualToString:@"AnnotationCreateSignature"] ||
                     [string isEqualToString:@"signatureToolButton"]) {
                self.toolManager.signatureAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateLine"] ||
                     [string isEqualToString:@"lineToolButton"]) {
                self.toolManager.lineAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateArrow"] ||
                     [string isEqualToString:@"arrowToolButton"]) {
                self.toolManager.arrowAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreatePolyline"] ||
                     [string isEqualToString:@"polylineToolButton"]) {
                self.toolManager.polylineAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateStamp"] ||
                     [string isEqualToString:@"stampToolButton"]) {
                self.toolManager.stampAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateRectangle"] ||
                     [string isEqualToString:@"rectangleToolButton"]) {
                self.toolManager.squareAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateEllipse"] ||
                     [string isEqualToString:@"ellipseToolButton"]) {
                self.toolManager.circleAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreatePolygon"] ||
                     [string isEqualToString:@"polygonToolButton"]) {
                self.toolManager.polygonAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreatePolygonCloud"] ||
                     [string isEqualToString:@"cloudToolButton"]) {
                self.toolManager.cloudyAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateFileAttachment"]) {
                self.toolManager.fileAttachmentAnnotationOptions.canCreate = value;
            }
        }
    }
}

- (void)setToolMode:(NSString *)toolMode
{
    if (toolMode.length == 0) {
        return;
    }
    
    Class toolClass = Nil;
    
    if( [toolMode isEqualToString:@"AnnotationEdit"] )
    {
        // multi-select not implemented
    }
    else if( [toolMode isEqualToString:@"AnnotationCreateSticky"])
    {
        toolClass = [PTStickyNoteCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateFreeHand"])
    {
        toolClass = [PTFreeHandCreate class];
    }
    else if ( [toolMode isEqualToString:@"TextSelect"] )
    {
        toolClass = [PTTextSelectTool class];
    }
    else if ( [toolMode isEqualToString:@"Pan"] )
    {
        toolClass = [PTPanTool class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateTextHighlight"])
    {
        toolClass = [PTTextHighlightCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateTextUnderline"])
    {
        toolClass = [PTTextUnderlineCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateTextSquiggly"])
    {
        toolClass = [PTTextSquigglyCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateTextStrikeout"])
    {
        toolClass = [PTTextStrikeoutCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateFreeText"])
    {
        toolClass = [PTFreeTextCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateCallout"])
    {
        // not supported
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateSignature"])
    {
        toolClass = [PTDigitalSignatureTool class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateLine"])
    {
        toolClass = [PTLineCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateArrow"])
    {
        toolClass = [PTArrowCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreatePolyline"])
    {
        toolClass = [PTPolylineCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateStamp"])
    {
        // not implemented
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateRectangle"])
    {
        toolClass = [PTRectangleCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateEllipse"])
    {
        toolClass = [PTEllipseCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreatePolygon"])
    {
        toolClass = [PTPolygonCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreatePolygonCloud"])
    {
        toolClass = [PTCloudCreate class];
    }
    
    // Adjustment - Apple Pencil and Eraser Tools
    else if ( [toolMode isEqualToString:@"ApplePencil"])
    {
        if (@available(iOS 13.1, *)) {
            toolClass = [PTPencilDrawingCreate class];
        }
    }
    else if ( [toolMode isEqualToString:@"Eraser"])
    {
        toolClass = [PTEraser class];
    }
    
    if (toolClass) {
        PTTool *tool = [self.documentViewController.toolManager changeTool:toolClass];
        
        tool.backToPanToolAfterUse = !self.continuousAnnotationEditing;
        
        if ([tool isKindOfClass:[PTFreeHandCreate class]]
            && ![tool isKindOfClass:[PTFreeHandHighlightCreate class]]) {
            ((PTFreeHandCreate *)tool).multistrokeMode = self.continuousAnnotationEditing;
        }
        
        // Adjustment - Apple Pencil
        if (@available(iOS 13.1, *)) {
            if ([tool isKindOfClass:[PTPencilDrawingCreate class]])
            {
                ((PTPencilDrawingCreate *)tool).shouldShowToolPicker = YES;
            }
        }
    }
}

- (BOOL)commitTool
{
    if ([self.toolManager.tool respondsToSelector:@selector(commitAnnotation)]) {
        [self.toolManager.tool performSelector:@selector(commitAnnotation)];
        
        [self.toolManager changeTool:[PTPanTool class]];
        
        return YES;
    }
    
    return NO;
}

- (void)setPageNumber:(int)pageNumber
{
    if (_pageNumber == pageNumber) {
        // No change.
        return;
    }
    
    BOOL success = NO;
    @try {
        success = [self.documentViewController.pdfViewCtrl SetCurrentPage:pageNumber];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        success = NO;
    }
    
    if (success) {
        _pageNumber = pageNumber;
    } else {
        NSLog(@"Failed to set current page number");
    }
}

#pragma mark - Annotation import/export

- (PTAnnot *)findAnnotWithUniqueID:(NSString *)uniqueID onPageNumber:(int)pageNumber
{
    if (uniqueID.length == 0 || pageNumber < 1) {
        return nil;
    }
    PTPDFViewCtrl *pdfViewCtrl = self.documentViewController.pdfViewCtrl;
    
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        NSArray<PTAnnot *> *annots = [pdfViewCtrl GetAnnotationsOnPage:pageNumber];
        for (PTAnnot *annot in annots) {
            if (![annot IsValid]) {
                continue;
            }
            
            // Check if the annot's unique ID matches.
            NSString *annotUniqueId = nil;
            PTObj *annotUniqueIdObj = [annot GetUniqueID];
            if ([annotUniqueIdObj IsValid]) {
                annotUniqueId = [annotUniqueIdObj GetAsPDFText];
            }
            if (annotUniqueId && [annotUniqueId isEqualToString:uniqueID]) {
                return annot;
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlockRead];
        }
    }
    
    return nil;
}

- (NSString *)exportAnnotationsWithOptions:(NSDictionary *)options
{
    PTPDFViewCtrl *pdfViewCtrl = self.documentViewController.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        if (!options || !options[@"annotList"]) {
            PTFDFDoc *fdfDoc = [[pdfViewCtrl GetDoc] FDFExtract:e_ptboth];
            return [fdfDoc SaveAsXFDFToString];
        } else {
            PTVectorAnnot *annots = [[PTVectorAnnot alloc] init];
            
            NSArray *arr = options[@"annotList"];
            for (NSDictionary *annotation in arr) {
                NSString *annotationId = annotation[@"id"];
                int pageNumber = ((NSNumber *)annotation[@"pageNumber"]).intValue;
                if (annotationId.length > 0) {
                    PTAnnot *annot = [self findAnnotWithUniqueID:annotationId
                                                    onPageNumber:pageNumber];
                    if ([annot IsValid]) {
                        [annots add:annot];
                    }
                }
            }
            
            if ([annots size] > 0) {
                PTFDFDoc *fdfDoc = [[pdfViewCtrl GetDoc] FDFExtractAnnots:annots];
                return [fdfDoc SaveAsXFDFToString];
            } else {
                return nil;
            }
        }
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlockRead];
        }
    }
    
    return nil;
}

- (void)importAnnotations:(NSString *)xfdfString
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        PTFDFDoc *fdfDoc = [PTFDFDoc CreateFromXFDF:xfdfString];
        
        [[pdfViewCtrl GetDoc] FDFUpdate:fdfDoc];
        [pdfViewCtrl Update:YES];
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlockRead];
        }
    }
}

#pragma mark - Flatten annotations

- (void)flattenAnnotations:(BOOL)formsOnly
{
    [self.toolManager changeTool:[PTPanTool class]];
    
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [pdfViewCtrl GetDoc];
        
        [doc FlattenAnnotations:formsOnly];
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
    
    [pdfViewCtrl Update:YES];
}

- (void)deleteAnnotations:(NSArray *)annotations
{
    if (annotations.count == 0) {
        return;
    }
    
    for (id annotationData in annotations) {
        if (![annotationData isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *dict = (NSDictionary *)annotationData;
        
        NSString *annotId = dict[@"id"];
        NSNumber *pageNumber = dict[@"pageNumber"];
        if (!annotId || !pageNumber) {
            continue;
        }
        int pageNumberValue = pageNumber.intValue;
        
        __block PTAnnot *annot = nil;
        NSError *error = nil;
        [self.pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
            
            annot = [self findAnnotWithUniqueID:annotId onPageNumber:pageNumberValue];
            if (![annot IsValid]) {
                NSLog(@"Failed to find annotation with id \"%@\" on page number %d",
                      annotId, pageNumberValue);
                annot = nil;
                return;
            }
            
            PTPage *page = [doc GetPage:pageNumberValue];
            if ([page IsValid]) {
                [page AnnotRemoveWithAnnot:annot];
            }
            
            [self.pdfViewCtrl UpdateWithAnnot:annot page_num:pageNumberValue];
        } error:&error];
        
        // Throw error as exception to reject promise.
        if (error) {
            @throw [NSException exceptionWithName:NSGenericException reason:error.localizedFailureReason userInfo:error.userInfo];
        } else if (annot) {
            [self.toolManager annotationRemoved:annot onPageNumber:pageNumberValue];
        }
    }
    
    [self.toolManager changeTool:[PTPanTool class]];
}

#pragma mark - Saving

- (void)saveDocumentWithCompletionHandler:(void (^)(NSString * _Nullable filePath))completionHandler
{
    if (![self isBase64String]) {
        NSString *filePath = self.documentViewController.coordinatedDocument.fileURL.path;
        
        [self.documentViewController saveDocument:e_ptincremental completionHandler:^(BOOL success) {
            if (completionHandler) {
                completionHandler((success) ? filePath : nil);
            }
        }];
    } else {
        __block NSString *base64String = nil;
        __block BOOL success = NO;
        NSError *error = nil;
        [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
            NSData *data = [doc SaveToBuf:0];
            
            base64String = [data base64EncodedStringWithOptions:0];
            success = YES;
        } error:&error];
        if (completionHandler) {
            completionHandler((error == nil) ? base64String : nil);
        }
    }
}

#pragma mark - Fields

- (void)setFlagForFields:(NSArray<NSString *> *)fields setFlag:(PTFieldFlag)flag toValue:(BOOL)value
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [pdfViewCtrl GetDoc];
        
        for (NSString *fieldName in fields) {
            PTField *field = [doc GetField:fieldName];
            if ([field IsValid]) {
                [field SetFlag:flag value:value];
            }
        }
        
        [pdfViewCtrl Update:YES];
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
}

- (void)setValueForFields:(NSDictionary<NSString *, id> *)map
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [pdfViewCtrl GetDoc];
        
        for (NSString *fieldName in map) {
            PTField *field = [doc GetField:fieldName];
            if ([field IsValid]) {
                id value = map[fieldName];
                [self setFieldValue:field value:value];
            }
        }
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
}

// write-lock acquired around this method
- (void)setFieldValue:(PTField *)field value:(id)value
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    
    const PTFieldType fieldType = [field GetType];
    
    // boolean or number
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *numberValue = (NSNumber *)value;
        
        if (fieldType == e_ptcheck) {
            const BOOL fieldValue = numberValue.boolValue;
            PTViewChangeCollection *changeCollection = [field SetValueWithBool:fieldValue];
            [pdfViewCtrl RefreshAndUpdate:changeCollection];
        }
        else if (fieldType == e_pttext) {
            NSString *fieldValue = numberValue.stringValue;
            
            PTViewChangeCollection *changeCollection = [field SetValueWithString:fieldValue];
            [pdfViewCtrl RefreshAndUpdate:changeCollection];
        }
    }
    // string
    else if ([value isKindOfClass:[NSString class]]) {
        NSString *fieldValue = (NSString *)value;
        
        if (fieldValue &&
            (fieldType == e_pttext || fieldType == e_ptradio)) {
            PTViewChangeCollection *changeCollection = [field SetValueWithString:fieldValue];
            [pdfViewCtrl RefreshAndUpdate:changeCollection];
        }
    }
}

#pragma mark - Collaboration

- (void)importAnnotationCommand:(NSString *)xfdfCommand initialLoad:(BOOL)initialLoad
{
    if (self.collaborationManager) {
        [self.collaborationManager importAnnotationsWithXFDFCommand:xfdfCommand
                                                          isInitial:initialLoad];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"set collabEnabled to true is required" userInfo:nil];
    }
}

#pragma mark - Viewer options

-(void)setNightModeEnabled:(BOOL)nightModeEnabled
{
    _nightModeEnabled = nightModeEnabled;
    
    [self applyViewerSettings];
}

#pragma mark - Top/bottom toolbar

-(void)setTopToolbarEnabled:(BOOL)topToolbarEnabled
{
    _topToolbarEnabled = topToolbarEnabled;
    
    [self applyViewerSettings];
}

-(void)setBottomToolbarEnabled:(BOOL)bottomToolbarEnabled
{
    _bottomToolbarEnabled = bottomToolbarEnabled;
    
    [self applyViewerSettings];
}

#pragma mark - Page indicator

-(void)setPageIndicatorEnabled:(BOOL)pageIndicatorEnabled
{
    _pageIndicatorEnabled = pageIndicatorEnabled;
    
    [self applyViewerSettings];
}

-(void)setPageIndicatorShowsOnPageChange:(BOOL)pageIndicatorShowsOnPageChange
{
    _pageIndicatorShowsOnPageChange = pageIndicatorShowsOnPageChange;
    
    [self applyViewerSettings];
}

-(void)setPageIndicatorShowsWithControls:(BOOL)pageIndicatorShowsWithControls
{
    _pageIndicatorShowsWithControls = pageIndicatorShowsWithControls;
    
    [self applyViewerSettings];
}

- (void)setAutoSaveEnabled:(BOOL)autoSaveEnabled
{
    _autoSaveEnabled = autoSaveEnabled;
    
    [self applyViewerSettings];
}

- (void)setPageChangeOnTap:(BOOL)pageChangeOnTap
{
    _pageChangeOnTap = pageChangeOnTap;
    
    [self applyViewerSettings];
}

- (void)setThumbnailViewEditingEnabled:(BOOL)enabled
{
    _thumbnailViewEditingEnabled = enabled;
    
    [self applyViewerSettings];
}

- (void)setSelectAnnotationAfterCreation:(BOOL)selectAnnotationAfterCreation
{
    _selectAnnotationAfterCreation = selectAnnotationAfterCreation;
    
    [self applyViewerSettings];
}

-(void)setHideAnnotMenuTools:(NSArray<NSString *> *)hideAnnotMenuTools
{
//    _hideAnnotMenuTools = hideAnnotMenuTools;
    
    NSMutableArray* hideMenuTools = [[NSMutableArray alloc] init];
    
    for (NSString* hideMenuTool in hideAnnotMenuTools) {
        PTExtendedAnnotType toolTypeToHide = [self reactAnnotationNameToAnnotType:hideMenuTool];
        [hideMenuTools addObject:@(toolTypeToHide)];
    }
    
    self.hideAnnotMenuToolsAnnotTypes = [hideMenuTools copy];
    
}

#pragma mark -

- (void)applyViewerSettings
{
    if (!self.documentViewController) {
        return;
    }
    
    [self applyReadonly];
    
    // Thumbnail editing enabled.
    self.documentViewController.thumbnailsViewController.editingEnabled = self.thumbnailViewEditingEnabled;
    
    // Select after creation.
    self.toolManager.selectAnnotationAfterCreation = self.selectAnnotationAfterCreation;
    
    // Auto save.
    self.documentViewController.automaticallySavesDocument = self.autoSaveEnabled;
    
    // Top toolbar.
    if (!self.topToolbarEnabled) {
        self.documentViewController.hidesControlsOnTap = NO;
        self.documentViewController.controlsHidden = YES;
    } else {
        self.documentViewController.hidesControlsOnTap = YES;
        self.documentViewController.controlsHidden = NO;
    }
    const BOOL translucent = self.documentViewController.hidesControlsOnTap;
    self.documentViewController.thumbnailSliderController.toolbar.translucent = translucent;
    self.documentViewController.navigationController.navigationBar.translucent = translucent;
    
    // Bottom toolbar.
    self.documentViewController.bottomToolbarEnabled = self.bottomToolbarEnabled;
    
    // Page indicator.
    self.documentViewController.pageIndicatorEnabled = self.pageIndicatorEnabled;
    
    // Page change on tap.
    self.documentViewController.changesPageOnTap = self.pageChangeOnTap;
    
    // Fit mode.
    if ([self.fitMode isEqualToString:@"FitPage"]) {
        [self.pdfViewCtrl SetPageViewMode:e_trn_fit_page];
        [self.pdfViewCtrl SetPageRefViewMode:e_trn_fit_page];
    }
    else if ([self.fitMode isEqualToString:@"FitWidth"]) {
        [self.pdfViewCtrl SetPageViewMode:e_trn_fit_width];
        [self.pdfViewCtrl SetPageRefViewMode:e_trn_fit_width];
    }
    else if ([self.fitMode isEqualToString:@"FitHeight"]) {
        [self.pdfViewCtrl SetPageViewMode:e_trn_fit_height];
        [self.pdfViewCtrl SetPageRefViewMode:e_trn_fit_height];
    }
    else if ([self.fitMode isEqualToString:@"Zoom"]) {
        [self.pdfViewCtrl SetPageViewMode:e_trn_zoom];
        [self.pdfViewCtrl SetPageRefViewMode:e_trn_zoom];
    }
    
    // Layout mode.
    [self applyLayoutMode];
    
    // Continuous annotation editing.
    self.toolManager.tool.backToPanToolAfterUse = !self.continuousAnnotationEditing;
    
    // Annotation author.
    self.toolManager.annotationAuthor = self.annotationAuthor;
    
    // Shows saved signatures.
    self.toolManager.showDefaultSignature = self.showSavedSignatures;
    
    // Disable UI elements.
    [self disableElementsInternal:self.disabledElements];
    
    // Disable tools.
    [self setToolsPermission:self.disabledTools toValue:NO];
    
    // Custom HTTP request headers.
    [self applyCustomHeaders];
    

    // Adjustment custom Init function for better clearity
    [self customInit];
}

- (void)applyLayoutMode
{
    if ([self.layoutMode isEqualToString:@"Single"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_single_page];
    }
    else if ([self.layoutMode isEqualToString:@"Continuous"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_single_continuous];
    }
    else if ([self.layoutMode isEqualToString:@"Facing"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing];
    }
    else if ([self.layoutMode isEqualToString:@"FacingContinuous"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing_continuous];
    }
    else if ([self.layoutMode isEqualToString:@"FacingCover"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing_cover];
    }
    else if ([self.layoutMode isEqualToString:@"FacingCoverContinuous"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing_continuous_cover];
    }
}

#pragma mark - Custom headers

- (void)setCustomHeaders:(NSDictionary<NSString *, NSString *> *)customHeaders
{
    _customHeaders = [customHeaders copy];
    
    self.needsCustomHeadersUpdate = YES;
    
    if (self.documentViewController) {
        [self applyCustomHeaders];
    }
}

- (void)applyCustomHeaders
{
    if (!self.needsCustomHeadersUpdate) {
        return;
    }
    
    self.documentViewController.additionalHTTPHeaders = self.customHeaders;
    
    self.needsCustomHeadersUpdate = NO;
}

#pragma mark - Readonly

- (void)setReadOnly:(BOOL)readOnly
{
    _readOnly = readOnly;
    
    [self applyViewerSettings];
}

- (void)applyReadonly
{
    // Enable readonly flag on tool manager *only* when not already readonly.
    // If the document is being streamed or converted, we don't want to accidentally allow editing by
    // disabling the readonly flag.
    if (![self.documentViewController.toolManager isReadonly]) {
        self.documentViewController.toolManager.readonly = self.readOnly;
    }
    
    self.documentViewController.thumbnailsViewController.editingEnabled = !self.readOnly;
}

#pragma mark - Fit mode

- (void)setFitMode:(NSString *)fitMode
{
    _fitMode = [fitMode copy];
    
    [self applyViewerSettings];
}

#pragma mark - Layout mode

- (void)setLayoutMode:(NSString *)layoutMode
{
    _layoutMode = [layoutMode copy];
    
    [self applyViewerSettings];
}

#pragma mark - Continuous annotation editing

- (void)setContinuousAnnotationEditing:(BOOL)continuousAnnotationEditing
{
    _continuousAnnotationEditing = continuousAnnotationEditing;
    
    [self applyViewerSettings];
}

#pragma mark - Annotation author

- (void)setAnnotationAuthor:(NSString *)annotationAuthor
{
    _annotationAuthor = [annotationAuthor copy];
    
    [self applyViewerSettings];
}

#pragma mark - Show saved signatures

- (void)setShowSavedSignatures:(BOOL)showSavedSignatures
{
    _showSavedSignatures = showSavedSignatures;
    
    [self applyViewerSettings];
}

#pragma mark - Actions

- (void)navButtonClicked
{
    if([self.delegate respondsToSelector:@selector(navButtonClicked:)]) {
        [self.delegate navButtonClicked:self];
    }
}

#pragma mark - Convenience

- (UIViewController *)findParentViewController
{
    UIResponder *parentResponder = self;
    while ((parentResponder = parentResponder.nextResponder)) {
        if ([parentResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)parentResponder;
        }
    }
    return nil;
}

-(PTExtendedAnnotType)reactAnnotationNameToAnnotType:(NSString*)reactString
{
    NSDictionary* typeMap = @{
        @"AnnotationCreateSticky" : @(PTExtendedAnnotTypeText),
        @"stickyToolButton" : @(PTExtendedAnnotTypeText),
        @"AnnotationCreateFreeHand" : @(PTExtendedAnnotTypeInk),
        @"AnnotationCreateTextHighlight" : @(PTExtendedAnnotTypeHighlight),
        @"AnnotationCreateTextUnderline" : @(PTExtendedAnnotTypeUnderline),
        @"AnnotationCreateTextSquiggly" : @(PTExtendedAnnotTypeSquiggly),
        @"AnnotationCreateTextStrikeout" : @(PTExtendedAnnotTypeStrikeOut),
        @"AnnotationCreateFreeText" : @(PTExtendedAnnotTypeFreeText),
        @"AnnotationCreateCallout" : @(PTExtendedAnnotTypeCallout),
        @"AnnotationCreateSignature" : @(PTExtendedAnnotTypeSignature),
        @"AnnotationCreateLine" : @(PTExtendedAnnotTypeLine),
        @"AnnotationCreateArrow" : @(PTExtendedAnnotTypeArrow),
        @"AnnotationCreatePolyline" : @(PTExtendedAnnotTypePolyline),
        @"AnnotationCreateStamp" : @(PTExtendedAnnotTypeStamp),
        @"AnnotationCreateRectangle" : @(PTExtendedAnnotTypeSquare),
        @"AnnotationCreateEllipse" : @(PTExtendedAnnotTypeCircle),
        @"AnnotationCreatePolygon" : @(PTExtendedAnnotTypePolygon),
        @"AnnotationCreatePolygonCloud" : @(PTExtendedAnnotTypeCloudy),
//        @"AnnotationCreateDistanceMeasurement" : @(),
//        @"AnnotationCreatePerimeterMeasurement" : @(),
//        @"AnnotationCreateAreaMeasurement" : @(),
        @"AnnotationCreateFileAttachment" : @(PTExtendedAnnotTypeFileAttachment),
        @"AnnotationCreateSound" : @(PTExtendedAnnotTypeSound),
//        @"FormCreateTextField" : @(),
//        @"FormCreateCheckboxField" : @(),
//        @"FormCreateRadioField" : @(),
//        @"FormCreateComboBoxField" : @(),
//        @"FormCreateListBoxField" : @()
    };
    
    
    PTExtendedAnnotType annotType = PTExtendedAnnotTypeUnknown;
    
    if( typeMap[reactString] )
    {
        annotType = [typeMap[reactString] unsignedIntValue];
    }

    return annotType;
    
}

#pragma mark - <PTDocumentViewControllerDelegate>

//- (BOOL)documentViewController:(PTDocumentViewController *)documentViewController shouldExportCachedDocumentAtURL:(NSURL *)cachedDocumentUrl
//{
//    // Don't export the downloaded file (ie. keep using the cache file).
//    return NO;
//}

- (BOOL)documentViewController:(PTDocumentViewController *)documentViewController shouldDeleteCachedDocumentAtURL:(NSURL *)cachedDocumentUrl
{
    // Don't delete the cache file.
    // (This will only be called if -documentViewController:shouldExportCachedDocumentAtURL: returns YES)
    return NO;
}

#pragma mark - <PTToolManagerDelegate>

- (UIViewController *)viewControllerForToolManager:(PTToolManager *)toolManager
{
    return self.documentViewController;
}

- (BOOL)toolManager:(PTToolManager *)toolManager shouldHandleLinkAnnotation:(PTAnnot *)annotation orLinkInfo:(PTLinkInfo *)linkInfo onPageNumber:(unsigned long)pageNumber
{
    if (![self.overrideBehavior containsObject:@"linkPress"]) {
        return YES;
    }
    
    __block NSString *url = nil;
    
    NSError *error = nil;
    [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
        // Check for a valid link annotation.
        if (![annotation IsValid] ||
            annotation.extendedAnnotType != PTExtendedAnnotTypeLink) {
            return;
        }
        
        PTLink *linkAnnot = [[PTLink alloc] initWithAnn:annotation];
        
        // Check for a valid URI action.
        PTAction *action = [linkAnnot GetAction];
        if (![action IsValid] ||
            [action GetType] != e_ptURI) {
            return;
        }
        
        PTObj *actionObj = [action GetSDFObj];
        if (![actionObj IsValid]) {
            return;
        }
        
        // Get the action's URI.
        PTObj *uriObj = [actionObj FindObj:@"URI"];
        if ([uriObj IsValid] && [uriObj IsString]) {
            url = [uriObj GetAsPDFText];
        }
    } error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    if (url) {
        self.onChange(@{
            @"onBehaviorActivated": @"onBehaviorActivated",
            @"action": @"linkPress",
            @"data": @{
                @"url": url,
            },
        });
        
        // Link handled.
        return NO;
    }
    
    return YES;
}

#pragma mark - <RNTPTDocumentViewControllerDelegate>

- (void)rnt_documentViewControllerDocumentLoaded:(PTDocumentViewController *)documentViewController
{
    if (self.initialPageNumber > 0) {
        [documentViewController.pdfViewCtrl SetCurrentPage:self.initialPageNumber];
    }
    
    if ([self isReadOnly] && ![self.documentViewController.toolManager isReadonly]) {
        self.documentViewController.toolManager.readonly = YES;
    }
    
    [self applyLayoutMode];
    
    if ([self.delegate respondsToSelector:@selector(documentLoaded:)]) {
        [self.delegate documentLoaded:self];
    }
}

- (void)rnt_documentViewControllerDidZoom:(PTDocumentViewController *)documentViewController
{
    const double zoom = self.pdfViewCtrl.zoom * self.pdfViewCtrl.zoomScale;
    
    if ([self.delegate respondsToSelector:@selector(zoomChanged:zoom:)]) {
        [self.delegate zoomChanged:self zoom:zoom];
    }
}

- (BOOL)rnt_documentViewControllerShouldGoBackToPan:(PTDocumentViewController *)documentViewController
{
    return !self.continuousAnnotationEditing;
}

- (BOOL)rnt_documentViewControllerIsTopToolbarEnabled:(PTDocumentViewController *)documentViewController
{
    return self.topToolbarEnabled;
}

- (NSArray<NSDictionary<NSString *, id> *> *)annotationDataForAnnotations:(NSArray<PTAnnot *> *)annotations pageNumber:(int)pageNumber
{
    NSMutableArray<NSDictionary<NSString *, id> *> *annotationData = [NSMutableArray array];
    
    if (annotations.count > 0) {
        [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc *doc) {
            for (PTAnnot *annot in annotations) {
                if (![annot IsValid]) {
                    continue;
                }
                
                NSString *uniqueId = nil;
                
                PTObj *uniqueIdObj = [annot GetUniqueID];
                if ([uniqueIdObj IsValid] && [uniqueIdObj IsString]) {
                    uniqueId = [uniqueIdObj GetAsPDFText];
                }
                
                PTPDFRect *screenRect = [self.pdfViewCtrl GetScreenRectForAnnot:annot
                                                                       page_num:pageNumber];
                [annotationData addObject:@{
                    @"id": (uniqueId ?: @""),
                    @"pageNumber": @(pageNumber),
                    @"rect": @{
                            @"x1": @([screenRect GetX1]),
                            @"y1": @([screenRect GetY1]),
                            @"x2": @([screenRect GetX2]),
                            @"y2": @([screenRect GetY2]),
                    },
                }];
            }
        } error:nil];
    }

    return [annotationData copy];
}

- (void)rnt_documentViewController:(PTDocumentViewController *)documentViewController didSelectAnnotations:(NSArray<PTAnnot *> *)annotations onPageNumber:(int)pageNumber
{
    NSArray<NSDictionary<NSString *, id> *> *annotationData = [self annotationDataForAnnotations:annotations pageNumber:pageNumber];
    
    if ([self.delegate respondsToSelector:@selector(annotationsSelected:annotations:)]) {
        [self.delegate annotationsSelected:self annotations:annotationData];
    }
}

- (BOOL)rnt_documentViewController:(PTDocumentViewController *)documentViewController filterMenuItemsForAnnotationSelectionMenu:(UIMenuController *)menuController forAnnotation:(PTAnnot*)annot
{
    
    PTExtendedAnnotType annotType = [annot extendedAnnotType];
    
    if( [self.hideAnnotMenuToolsAnnotTypes containsObject:@(annotType)] )
    {
        return NO;
    }
        
    // Mapping from menu item title to identifier.
    NSDictionary<NSString *, NSString *> *map = @{
        @"Style": @"style",
        @"Note": @"note",
        @"Copy": @"copy",
        @"Delete": @"delete",
        @"Type": @"markupType",
        @"Search": @"search",
        @"Edit": @"editInk",
        @"Edit Text": @"editText",
        @"Flatten": @"flatten",
        @"Open": @"openAttachment",
    };
    // Get the localized title for each menu item.
    NSMutableDictionary<NSString *, NSString *> *localizedMap = [NSMutableDictionary dictionary];
    for (NSString *key in map) {
        NSString *localizedKey = PTLocalizedString(key, nil);
        if (!localizedKey) {
            localizedKey = key;
        }
        localizedMap[localizedKey] = map[key];
    }
    
    NSMutableArray<UIMenuItem *> *permittedItems = [NSMutableArray array];
    
    for (UIMenuItem *menuItem in menuController.menuItems) {
        NSString *menuItemId = localizedMap[menuItem.title];
        
        if (self.annotationMenuItems.count == 0) {
            [permittedItems addObject:menuItem];
        }
        else {
            if (menuItemId && [self.annotationMenuItems containsObject:menuItemId]) {
                [permittedItems addObject:menuItem];
            }
        }
        
        // Override action of of overridden annotation menu items.
        if (menuItemId && [self.overrideAnnotationMenuBehavior containsObject:menuItemId]) {
            NSString *actionName = [NSString stringWithFormat:@"overriddenPressed_%@",
                                    menuItemId];
            const SEL selector = NSSelectorFromString(actionName);
            
            RNTPT_addMethod([self class], selector, ^(id self) {
                [self overriddenMenuItemPressed:menuItemId];
            });
            
            menuItem.action = selector;
        }
    }
    
    menuController.menuItems = [permittedItems copy];
    
    return YES;
}

- (void)overriddenMenuItemPressed:(NSString *)menuItemId
{
    NSMutableArray<PTAnnot *> *annotations = [NSMutableArray array];
    
    if ([self.toolManager.tool isKindOfClass:[PTAnnotEditTool class]]) {
        PTAnnotEditTool *annotEdit = (PTAnnotEditTool *)self.toolManager.tool;
        if (annotEdit.selectedAnnotations.count > 0) {
            [annotations addObjectsFromArray:annotEdit.selectedAnnotations];
        }
    }
    else if (self.toolManager.tool.currentAnnotation) {
        [annotations addObject:self.toolManager.tool.currentAnnotation];
    }
    
    const int pageNumber = self.toolManager.tool.annotationPageNumber;
    
    NSArray<NSDictionary<NSString *, id> *> *annotationData = [self annotationDataForAnnotations:annotations pageNumber:pageNumber];
        
    if ([self.delegate respondsToSelector:@selector(annotationMenuPressed:annotationMenu:annotations:)]) {
        [self.delegate annotationMenuPressed:self annotationMenu:menuItemId annotations:annotationData];
    }
}

#pragma mark - <PTDocumentViewControllerDelegate>

- (void)documentViewController:(PTDocumentViewController *)documentViewController didFailToOpenDocumentWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(documentError:error:)]) {
        [self.delegate documentError:self error:error.localizedFailureReason];
    }
}

#pragma mark - <PTCollaborationServerCommunication>

- (NSString *)documentID
{
    return self.document;
}

- (NSString *)userID
{
    return self.currentUser;
}

- (void)documentLoaded
{
    // Use rnt_documentViewControllerDocumentLoaded
}

- (void)localAnnotationAdded:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self rnt_sendExportAnnotationCommandWithAction:@"add"
                                        xfdfCommand:collaborationAnnotation.xfdf];
}

- (void)localAnnotationModified:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self rnt_sendExportAnnotationCommandWithAction:@"modify"
                                        xfdfCommand:collaborationAnnotation.xfdf];
}

- (void)localAnnotationRemoved:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self rnt_sendExportAnnotationCommandWithAction:@"delete"
                                        xfdfCommand:collaborationAnnotation.xfdf];
}

- (void)rnt_sendExportAnnotationCommandWithAction:(NSString *)action xfdfCommand:(NSString *)xfdfCommand
{
    if ([self.delegate respondsToSelector:@selector(exportAnnotationCommand:action:xfdfCommand:)]) {
        [self.delegate exportAnnotationCommand:self action:action xfdfCommand:xfdfCommand];
    }
}

#pragma mark - Notifications

- (void)documentViewControllerDidOpenDocumentWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController) {
        return;
    }
    
    if ([self isReadOnly] && ![self.documentViewController.toolManager isReadonly]) {
        self.documentViewController.toolManager.readonly = YES;
    }
}

- (void)pdfViewCtrlDidChangePageWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController.pdfViewCtrl) {
        return;
    }
    
    int previousPageNumber = ((NSNumber *)notification.userInfo[PTPDFViewCtrlPreviousPageNumberUserInfoKey]).intValue;
    int pageNumber = ((NSNumber *)notification.userInfo[PTPDFViewCtrlCurrentPageNumberUserInfoKey]).intValue;
    
    _pageNumber = pageNumber;
    
    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(pageChanged:previousPageNumber:)]) {
        [self.delegate pageChanged:self previousPageNumber:previousPageNumber];
    }
}

- (void)toolManagerDidAddAnnotationWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController.toolManager) {
        return;
    }
    
    PTAnnot *annot = notification.userInfo[PTToolManagerAnnotationUserInfoKey];
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    NSString *annotId = [[annot GetUniqueID] IsValid] ? [[annot GetUniqueID] GetAsPDFText] : @"";
    if (annotId.length == 0) {
        PTPDFViewCtrl *pdfViewCtrl = self.documentViewController.pdfViewCtrl;
        BOOL shouldUnlock = NO;
        @try {
            [pdfViewCtrl DocLock:YES];
            shouldUnlock = YES;
            
            annotId = [NSUUID UUID].UUIDString;
            [annot SetUniqueID:annotId id_buf_sz:0];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        }
        @finally {
            if (shouldUnlock) {
                [pdfViewCtrl DocUnlock];
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(annotationChanged:annotation:action:)]) {
        [self.delegate annotationChanged:self annotation:@{
            @"id": annotId,
            @"pageNumber": @(pageNumber),
        } action:@"add"];
    }
}

- (void)toolManagerDidModifyAnnotationWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController.toolManager) {
        return;
    }
    
    PTAnnot *annot = notification.userInfo[PTToolManagerAnnotationUserInfoKey];
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    NSString *annotId = [[annot GetUniqueID] IsValid] ? [[annot GetUniqueID] GetAsPDFText] : @"";
    
    if ([self.delegate respondsToSelector:@selector(annotationChanged:annotation:action:)]) {
        [self.delegate annotationChanged:self annotation:@{
            @"id": annotId,
            @"pageNumber": @(pageNumber),
        } action:@"modify"];
    }
}

- (void)toolManagerDidRemoveAnnotationWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController.toolManager) {
        return;
    }
    
    PTAnnot *annot = notification.userInfo[PTToolManagerAnnotationUserInfoKey];
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    NSString *annotId = [[annot GetUniqueID] IsValid] ? [[annot GetUniqueID] GetAsPDFText] : @"";
    
    if ([self.delegate respondsToSelector:@selector(annotationChanged:annotation:action:)]) {
        [self.delegate annotationChanged:self annotation:@{
            @"id": annotId,
            @"pageNumber": @(pageNumber),
        } action:@"remove"];
    }
}







#pragma mark - Custom CAT Functions

- (void)customInit
{
    // Gesture Control
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.documentViewController.pdfViewCtrl handleTap:tapGestureRecognizer];
    self.documentViewController.hidesControlsOnTap = NO;


    // Settings Button
    self.documentViewController.viewerSettingsButtonHidden = YES;
    self.documentViewController.settingsViewController.popoverPresentationController.permittedArrowDirections = (UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown);
    self.documentViewController.thumbnailSliderController.trailingToolbarItem = self.documentViewController.settingsButtonItem; // you don't need to create a new UIBarButtonItem object
    
    
    // Translucent Thumbnail Slider
    self.documentViewController.navigationController.navigationBar.translucent = YES;
    self.documentViewController.thumbnailSliderController.toolbar.translucent = YES;
    
    
    
    // Native Sidebar Tests
    UIViewController *bookmarks = self.documentViewController.navigationListsViewController.bookmarkViewController;
    [self.documentViewController.navigationListsViewController removeListViewController:bookmarks];
    
    UIViewController *annotations = self.documentViewController.navigationListsViewController.annotationViewController;
    [self.documentViewController.navigationListsViewController removeListViewController:annotations];
    
    
    UIViewController *thumbnails = self.documentViewController.thumbnailsViewController;
    [self.documentViewController.navigationListsViewController addListViewController:thumbnails];
    
    
    UIViewController *newCtrl = [[UIViewController alloc] init];
    newCtrl.view.backgroundColor = [UIColor redColor];
    
//    UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
//    spacer.backgroundColor =[UIColor greenColor];
//    [newCtrl.view addSubview:spacer];
//
//    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 200, 200, 40)];
//
//    [newCtrl.view addSubview:searchBar];
//
    
    [self.documentViewController.navigationListsViewController addListViewController:newCtrl];
}




- (NSArray<NSString *> *)getThumbnails:(NSString *)fileName
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    PTPDFDoc *pdfDoc = [pdfViewCtrl GetDoc];
    
    NSMutableArray *thumbnails = [NSMutableArray new];
    int pageCount = [pdfDoc GetPageCount];
    
    NSError *error = nil;
    
    for(int pageNumber = 1; pageNumber <= pageCount; pageNumber++ ) {
        
        [pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
            
            PTPDFDraw* draw = [[PTPDFDraw alloc] initWithDpi:72];
            PTPage* page = [doc GetPage:pageNumber];
            
            // First, we need to save the document to the apps sandbox.
            NSString *name = [NSString stringWithFormat:@"%@-%i.png", fileName, pageNumber];
            NSString* fullFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
            
            PTPDFRect* cropBox = [page GetCropBox];
            int width = [cropBox Width];
            int height = [cropBox Height];

            [draw SetImageSize:200 height:300 preserve_aspect_ratio:false];
            [draw Export:page filename:fullFileName format:@"png"];
            
            [thumbnails addObject:fullFileName];
            
        } error:&error];
    
    }
    
    return thumbnails;
}

















// Custom Search
- (NSArray<NSDictionary<NSString *, NSString *> *> *)search:(NSString *)searchString
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    PTPDFDoc *pdfDoc = [pdfViewCtrl GetDoc];
    
    PTTextSearch *search = [[PTTextSearch alloc] init];
    unsigned int mode = e_ptwhole_word|e_pthighlight|e_ptambient_string;
    NSString *pattern = searchString;
    [search Begin:pdfDoc pattern:pattern mode:mode start_page:-1 end_page:-1];
    
    
    NSMutableArray *searchResults = [NSMutableArray new];
    bool moreToFind = true;

    while (moreToFind)
    {
        PTSearchResult *result = [search Run];
        if (result)
        {
            
            // Serach Result
            if( [result GetMatch] != nil ) {
                NSDictionary *oneSearchResult = @{
                    @"match": [result GetMatch],
                    @"page": [NSNumber numberWithInt:[result GetPageNumber]],
                    @"ambient": [result GetAmbientString]
                 };
                NSLog(@"%@", oneSearchResult);
                
                [searchResults addObject: oneSearchResult];
            }
            
            // Text Highlights
            PTHighlights *hlts = [result GetHighlights];
            [hlts Begin: pdfDoc];
            
            while ( [hlts HasNext] )
            {
                NSLog(@"The current highlight is from page: %d", [hlts GetCurrentPageNumber]);
                
                PTPage *cur_page = [pdfDoc GetPage: [hlts GetCurrentPageNumber]];
                PTVectorQuadPoint *quads = [hlts GetCurrentQuads];
                int i = 0;
                for ( ; i < [quads size]; ++i )
                {
                    PTQuadPoint *q = [quads get: i];
                    double x1 = MIN(MIN(MIN([[q getP1] getX], [[q getP2] getX]), [[q getP3] getX]), [[q getP4] getX]);
                    double x2 = MAX(MAX(MAX([[q getP1] getX], [[q getP2] getX]), [[q getP3] getX]), [[q getP4] getX]);
                    double y1 = MIN(MIN(MIN([[q getP1] getY], [[q getP2] getY]), [[q getP3] getY]), [[q getP4] getY]);
                    double y2 = MAX(MAX(MAX([[q getP1] getY], [[q getP2] getY]), [[q getP3] getY]), [[q getP4] getY]);
                    PTPDFRect * rect = [[PTPDFRect alloc] initWithX1: x1 y1: y1 x2: x2 y2: y2];
    
                    UIView *view = [[UIView alloc] init];
                    UIColor *color = [UIColor colorWithRed: 0.98 green: 0.46 blue: 0.08 alpha: 1.00];
                    view.backgroundColor = color;
                    view.layer.compositingFilter = @"multiplyBlendMode";

                    int toPage = [hlts GetCurrentPageNumber];
                    [pdfViewCtrl addFloatingView:view toPage:toPage withPageRect:rect noZoom:NO];
                }
                [hlts Next];
            }
            
            moreToFind = [result IsFound];
        }
    }
    
    return [searchResults copy];
}



- (void)clearSearch
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    [pdfViewCtrl clearFloatingViews];
}



- (void)findText
{
    PTDocumentViewController *docViewCtrl = self.documentViewController;
    [docViewCtrl showSearchViewController];
}



- (void)showSettings
{
    PTDocumentViewController *docViewCtrl = self.documentViewController;
    [docViewCtrl settingsViewController];
}



- (void)toggleSlider:(BOOL)toggle;
{
    PTDocumentViewController *docViewCtrl = self.documentViewController;
    
//    BOOL sliderHidden = [docViewCtrl isThumbnailSliderHidden];
//    NSLog(@"SLIDER HIDDEN %d", sliderHidden);
    
    if (toggle) {
        [docViewCtrl setThumbnailSliderHidden:NO animated:YES];
    } else {
        [docViewCtrl setThumbnailSliderHidden:YES animated:YES];
    }
}



- (void)appendSchoolLogo:(NSString *)base64String duplex:(BOOL)isDuplex
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    PTPDFDoc *pdfDoc = [pdfViewCtrl GetDoc];
    
    int pages = [pdfDoc GetPageCount];

    NSURL *url = [NSURL URLWithString:base64String];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    
    
    int maxImageWidth = 100;
    int maxImageHeight = 100;
    
    int offsetTop = 30;
    int offsetHorizontal = 50;
    

    for (int page = 1; page <= pages; page++)
    {
        UIImage *image = [UIImage imageWithData:imageData];
        UIImageView * imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(0, 0, maxImageWidth, maxImageHeight);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, maxImageWidth, maxImageHeight)];
        [view addSubview:imageView];
        
        PTPage *pageObject = [pdfDoc GetPage:page];
        
        double width = [pageObject GetPageWidth:e_pttrim];
        double height = [pageObject GetPageHeight:e_pttrim];
        
        if (isDuplex) {
            PTPDFRect *topLeft = [[PTPDFRect alloc] initWithX1:0 y1:height x2:maxImageWidth y2:(height-maxImageHeight)];
            PTPDFRect *topRight = [[PTPDFRect alloc] initWithX1:(width - maxImageWidth) y1:height x2:width y2:(height-maxImageHeight)];
            [pdfViewCtrl addFloatingView:view toPage:page withPageRect: (page % 2 ? topLeft : topRight) noZoom:NO];
        } else {
            PTPDFRect *topLeft = [[PTPDFRect alloc] initWithX1:0 y1:height x2:maxImageWidth y2:maxImageHeight];
            [pdfViewCtrl addFloatingView:view toPage:page withPageRect:topLeft noZoom:NO];
        }
    }
}



// Return dimensions
- (NSDictionary<NSString *, NSNumber *> *)getDimensions
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    PTPDFDoc *pdfDoc = [pdfViewCtrl GetDoc];
    PTPage *firstPage = [pdfDoc GetPage:1];
    
    NSNumber *width = [NSNumber numberWithDouble:[firstPage GetPageWidth:e_pttrim]];
    NSNumber *height = [NSNumber numberWithDouble:[firstPage GetPageHeight:e_pttrim]];
    
    NSDictionary *dimensions = @{
       @"width": width,
       @"height": height,
    };

    return dimensions;
}



// Jump To Page
- (void)jumpTo:(int)page_num
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    [pdfViewCtrl SetCurrentPage:page_num];
}



// Rotate Page
- (void)rotate:(BOOL)ccw
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    PTPDFDoc *pdfDoc = [pdfViewCtrl GetDoc];
    
    int page_number = [pdfViewCtrl GetCurrentPage];
    PTPage *page = [pdfDoc GetPage:page_number];
    
    PTRotate originalRotation = [page GetRotation];
    PTRotate newRotation;
        
    if (!ccw) {
        switch (originalRotation)
        {
          case e_pt0:   newRotation = e_pt90;  break;
          case e_pt90:  newRotation = e_pt180; break;
          case e_pt180: newRotation = e_pt270; break;
          case e_pt270: newRotation = e_pt0;   break;
          default:      newRotation = e_pt0;   break;
        }
    } else {
        switch (originalRotation)
        {
          case e_pt0:   newRotation = e_pt270; break;
          case e_pt270: newRotation = e_pt180; break;
          case e_pt180: newRotation = e_pt90;  break;
          case e_pt90:  newRotation = e_pt0;   break;
          default:      newRotation = e_pt0;   break;
        }
    }
    
    [page SetRotation:newRotation];
    [ pdfViewCtrl UpdatePageLayout ];
}



// Outline Manager
- (NSArray<NSDictionary<NSString *, id> *> *)PrintOutlineTree:(PTBookmark *)item outlineArr:(NSMutableArray *)outlineArr
{
    for (; [item IsValid]; item=[item GetNext]) {

        PTAction *action = [item GetAction];
        PTDestination *dest = [action GetDest];
        PTPage *page = [dest GetPage];
            
        NSDictionary *outlineElement = @{
           @"name": [item GetTitle],
           @"indent": [NSNumber numberWithInt:[item GetIndent]],
           @"page": [NSNumber numberWithInt:[page GetIndex]],
        };

        
        // NSLog(@"Outline Element: %@", outlineElement);
        
        
        // Some CAT PDFs have broken outlines, leading to mutlitple nested outlines
        // Luckily the redundant broken outlines all come with page = 0
        if ( [page GetIndex] != 0) {
            [outlineArr addObject:outlineElement];
        }

        
        // If this Bookmark has children do it again
        if ([item HasChildren]) {
            [self PrintOutlineTree:[item GetFirstChild] outlineArr:outlineArr];
        }
    }
    
    return [outlineArr copy];
}



- (NSArray<NSDictionary<NSString *, id> *> *)getOutline
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    PTPDFDoc *pdfDoc = [pdfViewCtrl GetDoc];

    PTBookmark *root = [pdfDoc GetFirstBookmark];
    
    NSMutableArray *outline = [[NSMutableArray alloc] init];
    
    NSArray *test = [[NSArray alloc] initWithArray:[self PrintOutlineTree:root outlineArr:outline]];

    NSLog(@"Final array %@", [test copy]);

    return [outline copy];
}



- (void)addBookmark
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    PTPDFDoc *pdfDoc = [pdfViewCtrl GetDoc];
    
    PTBookmarkManager *bookmarks = [[PTBookmarkManager alloc] init];
    
    int page_number = [pdfViewCtrl GetCurrentPage];
    PTUserBookmark *thisBookmark = [[PTUserBookmark alloc] initWithTitle:@"test" pageNumber:page_number];
    
    [bookmarks addBookmark:thisBookmark forDoc:pdfDoc];
}



@end

//
//  MFMailComposeViewController+BlocksKit.m
//  BlocksKit
//

#import "A2DynamicDelegate.h"
#import "MFMailComposeViewController+BlocksKit.h"
#import "NSObject+A2BlockDelegate.h"

#pragma mark Custom delegate

@interface A2DynamicMFMailComposeViewControllerDelegate : A2DynamicDelegate <MFMailComposeViewControllerDelegate>

@end

@implementation A2DynamicMFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	id realDelegate = self.realDelegate;
	BOOL shouldDismiss = (realDelegate && [realDelegate respondsToSelector:@selector(mailComposeController:didFinishWithResult:error:)]);
	if (shouldDismiss)
		[realDelegate mailComposeController:controller didFinishWithResult:result error:error];

	void (^block)(MFMailComposeViewController *, MFMailComposeResult, NSError *) = [self blockImplementationForMethod:_cmd];
	if (shouldDismiss) {
		if (block) block(controller, result, error);
	} else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
		__weak typeof(controller) weakController = controller;
		[controller dismissViewControllerAnimated:YES completion:^{
			typeof(&*weakController) strongController = weakController;
			if (block) block(strongController, result, error);
		}];
#else
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
		if ([controller respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
			__weak typeof(controller) weakController = controller;
			[controller dismissViewControllerAnimated:YES completion:^{
				typeof(&*weakController) strongController = weakController;
				if (block) block(strongController, result, error);
			}];
		} else {
#endif
			[controller dismissModalViewControllerAnimated:YES];
			if (block) block(controller, result, error);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
		}
#endif
#endif
	}
}

@end

#pragma mark Category

@implementation MFMailComposeViewController (BlocksKit)

@dynamic bk_completionBlock;

__attribute__((constructor)) static void initialize_MFMailComposeViewController(void) {
	@autoreleasepool {
		[[MFMailComposeViewController class] bk_registerDynamicDelegateNamed:@"mailComposeDelegate"];
		[[MFMailComposeViewController class] bk_linkDelegateMethods:@{ @"bk_completionBlock": @"mailComposeController:didFinishWithResult:error:" }];
	}
}

@end

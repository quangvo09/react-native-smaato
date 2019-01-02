
#import "RNSmaatoRewarded.h"

#if __has_include(<React/RCTUtils.h>)
#import <React/RCTUtils.h>
#else
#import "RCTUtils.h"
#endif

static NSString *const kEventAdLoaded = @"rewardedVideoAdLoaded";
static NSString *const kEventAdFailedToLoad = @"rewardedVideoAdFailedToLoad";
static NSString *const kEventAdOpened = @"rewardedVideoAdOpened";
static NSString *const kEventAdClosed = @"rewardedVideoAdClosed";
static NSString *const kEventRewarded = @"rewardedVideoAdRewarded";
static NSString *const kEventVideoStarted = @"rewardedVideoAdVideoStarted";
static NSString *const kEventVideoCompleted = @"rewardedVideoAdVideoCompleted";

@implementation RNSmaatoRewarded
{
    NSString *_adUnitID;
    SOMARewardedVideo *_adView;
    RCTPromiseResolveBlock _requestAdResolve;
    RCTPromiseRejectBlock _requestAdReject;
    BOOL hasListeners;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents
{
    return @[
             kEventRewarded,
             kEventAdLoaded,
             kEventAdFailedToLoad,
             kEventAdOpened,
             kEventVideoStarted,
             kEventAdClosed,
             kEventVideoCompleted ];
}

#pragma mark exported methods

RCT_EXPORT_METHOD(setAdUnitID:(NSString *)adUnitID)
{
    _adUnitID = adUnitID;
}

RCT_EXPORT_METHOD(requestAd:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    _requestAdResolve = resolve;
    _requestAdReject = reject;

    if (_adView == nil) {
      _adView = [[SOMARewardedVideo alloc] init];;
      _adView.delegate = self;
    }

    [_adView load];
}

RCT_EXPORT_METHOD(showAd:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (_adView.isLoaded) {
        [_adView show];
        resolve(nil);
    }
    else {
      reject(@"E_AD_NOT_READY", @"Ad is not ready.", nil);
    }
}

RCT_EXPORT_METHOD(isReady:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNumber numberWithBool:_adView.isLoaded]]);
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

#pragma mark GADRewardBasedVideoAdDelegate

- (void)somaAdViewDidLoadAd:(SOMAAdView*)adview{
  NSLog(@"Ad View Loaded");
  if (hasListeners) {
    [self sendEventWithName:kEventAdLoaded body:nil];
  }
  _requestAdResolve(nil);
}

- (void)somaAdView:(SOMAAdView*)adview didFailToReceiveAdWithError:(NSError *)error{
  if (hasListeners) {
    NSDictionary *jsError = RCTJSErrorFromCodeMessageAndNSError(@"E_AD_FAILED_TO_LOAD", error.localizedDescription, error);
    [self sendEventWithName:kEventAdFailedToLoad body:jsError];
  }
  
  _requestAdReject(@"E_AD_FAILED_TO_LOAD", error.localizedDescription, error);
}

- (BOOL)somaAdViewShouldEnterFullscreen:(SOMAAdView*)adview{
  if (hasListeners) {
    [self sendEventWithName:kEventAdOpened body:nil];
  }

  return YES;
}

- (void)somaAdView:(SOMAAdView *)adview didReceiveVideoAdEvent:(SOMAVideoAdTrackingEvent)event {
    if (event == SOMAVideoAdTrackingEventStart) {
      if (hasListeners) {
        [self sendEventWithName:kEventVideoStarted body:nil];
      }
    } else if (event == SOMAVideoAdTrackingEventFirstQuartile) {
        NSLog(@"Video Ad reached first quartile");
    } else if (event == SOMAVideoAdTrackingEventMidpoint) {
        NSLog(@"Video Ad reached mid point");
    } else if (event == SOMAVideoAdTrackingEventThirdQuartile) {
        NSLog(@"Video Ad reached third quartile");
    } else if (event == SOMAVideoAdTrackingEventComplete) {
      if (hasListeners) {
        [self sendEventWithName:kEventVideoCompleted body:nil];
        [self sendEventWithName:kEventRewarded body:nil];
      }
    }
}

- (void)somaAdViewWillHide:(SOMAAdView*)adview{
  if (hasListeners) {
    [self sendEventWithName:kEventAdClosed body:nil];
  }
}

@end
  

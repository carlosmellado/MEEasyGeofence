//
//  MEGeofenceTrackingManager.m
//  MEEasyGeofence
//
//  Created by Carlos Mellado on 04/10/16.
//  Copyright © 2016 Carlos Mellado. All rights reserved.
//

#import "MEGeofenceTrackingManager.h"

static const CGFloat kGeotrackingMinRadius = 100.0f;
static NSString *const kMEGeotrackingIdentifier = @"kMEGeotrackingIdentifier";

@interface MEGeofenceTrackingManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL geotrackingEnabled;

@end


@implementation MEGeofenceTrackingManager

- (instancetype)customInit {
    
    MEGeofenceTrackingManager *trackingManager = [super init];
    
    trackingManager.locationManager = [CLLocationManager new];
    trackingManager.locationManager.delegate = trackingManager;
    trackingManager.geofenceTrackingJumpMeters = kGeotrackingMinRadius;
    
    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        
        [trackingManager.locationManager startMonitoringSignificantLocationChanges];
    }
    
    return trackingManager;
}

+ (instancetype)sharedInstance {
    
    static MEGeofenceTrackingManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MEGeofenceTrackingManager alloc]customInit];
    });
    return manager;
}

+ (void)configureGeofenceManagerWithDelegate:(id<MEGeofenceTrackingManagerDelegate>)delegate enableGeotracking:(BOOL)geotracking {
    
    [[[self class] sharedInstance] setGeotrackingEnabled:geotracking];
    [[[self class] sharedInstance] setDelegate:delegate];
}

+ (void)askForLocationPermissions {
    
    [[[[self class] sharedInstance] locationManager] requestAlwaysAuthorization];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if ([[[[self class] sharedInstance] delegate] respondsToSelector:@selector(geofenceTrackerDidChangeAuthorizationStatus:)]) {
        
        [[[[self class] sharedInstance] delegate] geofenceTrackerDidChangeAuthorizationStatus:status];
    }

    if (status != kCLAuthorizationStatusNotDetermined) {
     
        if ([self shouldStartGeotracking] && self.geotrackingEnabled) {
            
            [self createRegionForGeotrackingWithLocation:[[[self class] sharedInstance]getCurrentLocation]];
        }
            
        [self manualCheck];
    }
}

- (void)reloadGeotrackingWithLocation:(CLLocation *)location {
    
    [self clearCurrentGeotracking];
    [self createRegionForGeotrackingWithLocation:location];
}

- (void)clearCurrentGeotracking {
    
    for (CLCircularRegion *region in [[[[self class] sharedInstance] locationManager] monitoredRegions]) {
        
        if ([region.identifier isEqualToString:kMEGeotrackingIdentifier]) {
            [[[[self class] sharedInstance] locationManager] stopMonitoringForRegion:region];
        }
    }
}

- (void)manualCheck {
    
    for (CLCircularRegion *region in [[[[self class] sharedInstance]locationManager]monitoredRegions]) {
        [[[[self class] sharedInstance]locationManager] requestStateForRegion:region];
    }
}

- (void)createRegionForGeotrackingWithLocation:(CLLocation *)location {
    
    [[self class] registerGeofenceWithCoordinates:location.coordinate radius:kGeotrackingMinRadius identifier:kMEGeotrackingIdentifier notifyOnEntry:NO notifyOnExit:YES];
    
    if ([self.delegate respondsToSelector:@selector(geotrackingDidGetLocation:)]) {
        [self.delegate geotrackingDidGetLocation:location];
    }
}

#pragma mark - Custom methods

- (BOOL)shouldStartGeotracking {
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        return NO;
    }
    
    BOOL shouldStart = YES;
    
    for (CLCircularRegion *region in [[self class] getRegisteredGeofences]) {
        if ([region.identifier isEqualToString:kMEGeotrackingIdentifier]) {
            if ([region containsCoordinate:[self getCurrentLocation].coordinate]) {
                shouldStart = NO;
            }
        }
    }
    
    return shouldStart;
}

+ (void)registerGeofenceWithCoordinates:(CLLocationCoordinate2D)coordinates
                               radius:(CLLocationDistance)radius
                           identifier:(NSString *)identifier
                        notifyOnEntry:(BOOL)entry
                         notifyOnExit:(BOOL)exit {
    
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:coordinates radius:radius identifier:identifier];
    [region setNotifyOnEntry:entry];
    [region setNotifyOnExit:exit];
    
    if ([[self class]canRegisterRegions]) {
        
        [[[[self class] sharedInstance] locationManager] startMonitoringForRegion:region];
    }
    else {
        
        [[[self class]sharedInstance]unableToMonitoreRegionsError];
    }
}

- (void)unableToMonitoreRegionsError {
    
    if ([self.delegate respondsToSelector:@selector(geofenceTrackerDidFailingRegisterForRegion:withError:)]) {
        
        NSError *customError = [[NSError alloc]initWithDomain:NSCocoaErrorDomain code:5000 userInfo:@{ NSLocalizedDescriptionKey : @"Geofence failed before adding it to the iOS system. It means that the device is not available to monitor regions at this time or that you exceeded the maximum of 20 geofences.\nRemember that if you'd activated the Geotracking system, it will use one slot."}];
        
        [self.delegate geofenceTrackerDidFailingRegisterForRegion:nil withError:customError];
    }
}

+ (BOOL)canRegisterRegions {
    
    NSInteger monitoredRegions = [[[self class] sharedInstance] locationManager].monitoredRegions.allObjects.count;
    
    return [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]] && monitoredRegions < 20;
}

+ (BOOL)removeGeofencePointWithIdentifier:(NSString *)identifier {
    
    for (CLCircularRegion *region in [[[self class] sharedInstance] locationManager].monitoredRegions) {
        
        if ([region.identifier isEqualToString:identifier]) {
        
            [[[[self class] sharedInstance] locationManager] stopMonitoringForRegion:region];
            return YES;
        }
    }
    
    return NO;
}

+ (void)removeAllGeofencePoints {
    
    for (CLCircularRegion *region in [[[self class] sharedInstance] locationManager].monitoredRegions) {
        
        if (![region.identifier isEqualToString:kMEGeotrackingIdentifier]) {
           [[[[self class] sharedInstance] locationManager] stopMonitoringForRegion:region];
        }
    }
}

+ (NSArray<__kindof CLCircularRegion *> *)getRegisteredGeofences {
   
    return [[[self class] sharedInstance] locationManager].monitoredRegions.allObjects;
}

- (CLLocation *)getCurrentLocation {
    
    return self.locationManager.location;
}

#pragma mark - Geolocation events

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    if ([self.delegate respondsToSelector:@selector(geofenceTrackerDidEnterOnGeofencedRegion:)]) {
        [self.delegate geofenceTrackerDidEnterOnGeofencedRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    
    if ([region.identifier isEqualToString:kMEGeotrackingIdentifier]) {
        
        [self reloadGeotrackingWithLocation:manager.location];
    }
    else {
        
        if ([self.delegate respondsToSelector:@selector(geofenceTrackerDidExitOnGeofencedRegion:)]) {
            [self.delegate respondsToSelector:@selector(geofenceTrackerDidExitOnGeofencedRegion:)];
        }
    }
}

//- (void)fixGeofencesIfNeeded {
//
//    BOOL hasToFix = YES;
//
//    for (CLCircularRegion *region in [[[self class] sharedInstance]locationManager].monitoredRegions) {
//
//        if ([region.identifier isEqualToString:kOutOfAreaStringIdentifier]) {
//
//            hasToFix = NO;
//            [[[[self class] sharedInstance]locationManager] requestStateForRegion:region];
//            break;
//        }
//    }
//
//    if (hasToFix) {
//
//        [self .encingFunctions];
//    }
//}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(nullable CLRegion *)region withError:(nonnull NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(geofenceTrackerDidFailingRegisterForRegion:withError:)]) {
        [self.delegate geofenceTrackerDidFailingRegisterForRegion:region withError:error];
    }
}

#pragma mark - Location Updates

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    for (CLCircularRegion *region in [[[self class] sharedInstance] locationManager].monitoredRegions) {
        
        if ([region.identifier isEqualToString:kMEGeotrackingIdentifier]) {
            
            [[[[self class] sharedInstance] locationManager]requestStateForRegion:region];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    
    [self.locationManager requestStateForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    
    if ([region isKindOfClass:[CLCircularRegion class]]) {
        CLCircularRegion *circular = (CLCircularRegion *)region;
        
        switch (state) {
            case CLRegionStateInside:
                if (![circular containsCoordinate:manager.location.coordinate]) {
                    state = CLRegionStateOutside;
                }
                break;
            case CLRegionStateOutside:
                if ([circular containsCoordinate:manager.location.coordinate]) {
                    state = CLRegionStateInside;
                }
                break;
            case CLRegionStateUnknown:
            default:
                break;
        }
        
        if (circular.notifyOnExit && state == CLRegionStateOutside) {
            [self locationManager:manager didExitRegion:region];
        }
        
        if (circular.notifyOnEntry && state == CLRegionStateInside) {
            [self locationManager:manager didEnterRegion:region];
        }
    }

}

# pragma mark - Setters

- (void)setGeofenceTrackingJumpMeters:(CGFloat)geofenceTrackingJumpMeters {
    
    _geofenceTrackingJumpMeters = fmax(kGeotrackingMinRadius, geofenceTrackingJumpMeters);
}

@end

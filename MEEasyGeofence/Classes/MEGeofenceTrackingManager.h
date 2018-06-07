//
//  MEGeofenceTrackingManager.h
//  MEEasyGeofence
//
//  Created by Carlos Mellado on 04/10/16.
//  Copyright © 2016 Carlos Mellado. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>


@protocol MEGeofenceTrackingManagerDelegate <NSObject>

@optional

/*!
 * @discussion Called when user changes the Authorization status of the location manager.
 * @param status You'll get the CLAuthorizationStatus as a parameter.
 */
- (void)geofenceTrackerDidChangeAuthorizationStatus:(CLAuthorizationStatus)status;

/*!
 * @discussion Called when user enters on a tracked area.
 * @param region You'll get the region
 */
- (void)geofenceTrackerDidEnterOnGeofencedRegion:(CLRegion *)region;

/*!
 * @discussion Called when user exits from tracked area.
 * @param region You'll get the region
 */
- (void)geofenceTrackerDidExitOnGeofencedRegion:(CLRegion *)region;

/*!
 * @discussion Called when a region starts geofencing.
 * @param region You'll get the region monitored
 */
- (void)geofenceTrackerDidSaveRegion:(CLRegion *)region;

/*!
 * @discussion Called when a region is removed from geofencing.
 * @param region You'll get the region removed
 */
- (void)geofenceTrackerDidRemoveRegion:(CLRegion *)region;

/*!
 * @discussion Used for Geotracking, it's called when user moves, resulting in a new location.
 * @param location You'll get the user's location
 */
- (void)geotrackingDidGetLocation:(CLLocation *)location;


- (void)geofenceTrackerDidFailingRegisterForRegion:(nullable CLRegion *)region withError:(nonnull NSError *)error;


@end


@interface MEGeofenceTrackingManager : NSObject

@property (nonatomic, weak) id<MEGeofenceTrackingManagerDelegate> delegate;
@property (nonatomic, assign) CGFloat geofenceTrackingJumpMeters;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/*!
 * @discussion Get singleton instance.
 */
+ (instancetype)sharedInstance;

/*!
 * @discussion Start the tracking sistem. If you want to use its delegate functions, you should set a delegate.
 */
+ (void)configureGeofenceManagerWithDelegate:(id<MEGeofenceTrackingManagerDelegate>)delegate enableGeotracking:(BOOL)geotracking;

/*!
 * @discussion Prompts the location permissions message. Needs "always" to work.
 */
+ (void)askForLocationPermissions;

/*!
 * @discussion Register a point to track.
 * @param coordinates CLLocationCoordinate2D as center coordinates to track.
 * @param radius CLLocationDistance as the meter radius you want to track.
 * @param identifier NSString as identifier
 * @param entry BOOL to track entries
 * @param exit BOOL to track exits
 */
+ (void)registerGeofenceWithCoordinates:(CLLocationCoordinate2D)coordinates
                                 radius:(CLLocationDistance)radius
                             identifier:(NSString *)identifier
                          notifyOnEntry:(BOOL)entry
                           notifyOnExit:(BOOL)exit;

/*!
 * @discussion Stop tracking a geofence point with this identifier.
 */
+ (BOOL)removeGeofencePointWithIdentifier:(NSString *)identifier;

/*!
 * @discussion Remove all tracked points.
 */
+ (void)removeAllGeofencePoints;

/*!
 * @discussion Get an NSArray of CLCircularRegion with the current registered geofences.
 */
+ (NSArray<__kindof CLCircularRegion *> *)getRegisteredGeofences;

/*!
 * @discussion Get the current location of the user.
 */
- (CLLocation*)getCurrentLocation;

- (void)removeAllGeofences;
//- (void)manualCheck;

@end

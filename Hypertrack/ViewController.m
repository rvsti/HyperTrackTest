//
//  ViewController.m
//  Hypertrack
//
//  Created by Raj on 12/02/17.
//  Copyright © 2017 Hypertrack. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>

@interface ViewController ()<UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) CLRegion *sanFranciscoRegion;

@property (strong, nonatomic) NSMutableArray *locationArray;
@property (strong, nonatomic) NSArray *filteredLocationArray;

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation ViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self loadDataFromJSON];
    
    [self initViews];
    
    [self.searchBar setShowsCancelButton:YES];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.mapView.frame style:UITableViewStylePlain];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.tableView setHidden:YES];
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.tableView];
}

- (void)loadDataFromJSON {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSMutableDictionary* dataDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSMutableArray* locationDictionaryArray = [[[[[[dataDict objectForKey:@"meta"] objectForKey:@"view"] objectForKey:@"columns"] objectAtIndex:10] objectForKey:@"cachedContents"] objectForKey:@"top"];
    _locationArray = [[NSMutableArray alloc] init];
    for (NSDictionary *locationDict in locationDictionaryArray) {
        [_locationArray addObject:[locationDict objectForKey:@"item"]];
    }
}

- (void)initViews {
    
    CLGeocoder* geocoder = [[CLGeocoder alloc] init];

    [geocoder geocodeAddressString:@"San Francisco" completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if (placemarks && placemarks.count > 0) {
            
            CLPlacemark *topResult = [placemarks objectAtIndex:0];
            
            _sanFranciscoRegion = topResult.region;
            
            CLLocationCoordinate2D coordinate = topResult.location.coordinate;
            
            GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:coordinate.latitude  longitude:coordinate.longitude zoom:11];
            [self.mapView setCamera:camera];
            
            [self addAllPins];
        }
    }];
}

- (void)addAllPins {
    
    for(int i = 0; i < _locationArray.count; i++) {
        
        CLGeocoder* geocoder = [[CLGeocoder alloc] init];
        
        [geocoder geocodeAddressString:_locationArray[i] inRegion:_sanFranciscoRegion completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            
            if (placemarks && placemarks.count > 0) {
                CLPlacemark *topResult = [placemarks objectAtIndex:0];
                
                GMSMarker *marker = [[GMSMarker alloc] init];
                marker.position = topResult.location.coordinate;
                marker.title = topResult.name;
                marker.snippet = topResult.name;
                
                marker.map = _mapView;
            }
        }];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _filteredLocationArray.count > 4 ? 4 : _filteredLocationArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    [cell.textLabel setText:_filteredLocationArray[indexPath.row]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    
    [self.tableView setHidden:NO];
    return YES;
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText {
    
    if ((theSearchBar.text != nil) && ([searchText length] > 0)) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", searchText];
        self.filteredLocationArray = [self.locationArray filteredArrayUsingPredicate:predicate];
        
    } else {
        self.filteredLocationArray = self.locationArray;
    }
    
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [self.tableView setHidden:YES];
    self.filteredLocationArray = nil;
    [self.searchBar endEditing:YES];
}

@end

# Social Explorer

Social explorer is an app that lets the user explore social network places an iPhone. Each place has a collection of fotos and information that the explorer can see and mark as favorite.

Currnetly, the information from the places are based on Instagram and Foursquare.

### Starting

First, the user starts the app and enable the social networks to use. 

![Discovery tab](images/start.png)

Once at least one network is selected, the user can "continue" and start exploring.

![Discovery tab](images/setup.png)

### Structure

The app has three tabs.

* a) Discovery: View used to explore locations using a map
* b) Favorites: Collection of favorite medias
* c) Settings: Social networks that will be used during the exploring.

### a) Discovery tab

The main screen of the app is the "Discovery tab". This tab is used to navigate and place "references". 

![Discovery tab](images/discover-tab.png)

A reference is a current point in map used to search for locations arround it. The user places a reference with a a "long tap" on the map. A pin represents a "reference". This reference will automatically get all the places in a ~1000 meters radius. Each place is called a "location" and it has photos that we can view. These photos are called "medias".

![Reference placed](images/reference-placed.png)

*Implementation note: a Reference has a many-to-many relationship with the locations. Each location has a one-to-many relationship with the media. This way a location won't be duplicated, but the media is owned by the location.*

We can move the references to continue exploring. Every time we move the reference (the pin), more locations around it are added to the reference, which gets more locations each time.
Whe the reference is added or moved it changes to "red", and once it start having locations it turns into purple. When you see it as green the reference is ready.

![Reference placed](images/reference-moved.png)

We can create as many references as we want. 

![Reference placed](images/reference-multi.png)

#### a.1) Reference info and actions

To view the reference's locations that we explored with a reference we can tap on the reference and a "bubble" will appear. This bubble (callout) give the user some information about the explored locations. We can click on the right icon of the buttle to view the locations and their media.

![Reference placed](images/reference-callout.png)

If the user clicks on the left button she can delete the reference.

In the map we have other controls on the bottom right that permits zooming on references or locations.

The "locate me" button will use the phone GPS to get the current location and move the view to that location.

The "little squares matrix" button lets view all the references we already have

The "little circles matrix" button lets the user view all the locations of the selected reference. 

#### a.2) Reference locations

After clicking the callout the list of places and ther medias will appear in the map and in a list.

![Reference placed](images/locations-initial.png)

Gere we can do a lot of things:
On the map we can tap the location and view the name. Also, the list will scroll to the corresponding medias.
Also, as we scroll the location will be selected in the map.

We can mark the media as favorite by tapping on the "start" button. To rever the action we do it again.

If we want to filter by social media we can select the segment we want. E.g. Only instagram.
 
To view the media you have to tap the row of the list.

And finally, we can delete the reference by tapping on the "gear" icon on the navigation menu.

### Media info

In this view we have a larger media. Here we can view a summary of the information about the media. Also, the location of the media in the map.

![Reference placed](images/media-eg1.png)

If the media came from Instagram a heart will appear and wil show if we liked it on Instagram or not.

We can also amr or unmark as favorite.

### Favorites
This tap show a collection of favorite photos.  

![Reference placed](images/favorite-eg1.png)

If we tap on a photo it will show the media info.

### Settings

This tap lets the user enable or disable social networks to use.

![Reference placed](images/settings-eg1.png)


## Important
This is a iOS 8 project submition for Udacity's 'Intro to iOS App Development with Swift'
It uses Swift 1.2, cocoapods 0.37.1 and iOS 8.3

## Development environment setup

1) Install cocoapods

`sudo gem install cocoapods`

2) Clone the project and go inside it
3) Install the pods

`pod install`

4) Open the project

`open SocialExplorer.xcworkspace`


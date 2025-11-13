import { HomePage } from '../home/HomePage';
import { MedicineTabPage } from '../medicine/MedicineTabPage';
import { ProfilePage } from '../profile/ProfilePage';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  @State homePageRefreshKey: number = 0; // 首页刷新触发器
  @State medicineTabPageRefreshKey: number = 0; // 用药Tab刷新触发器
  @State profilePageRefreshKey: number = 0; // 我的Tab刷新触发器

  // 页面显示时，根据当前Tab触发对应页面的刷新
  onPageShow() {
    console.log('MainPage onPageShow, currentIndex:', this.currentIndex);
    if (this.currentIndex === 0) {
      this.homePageRefreshKey++; // 触发首页刷新
    } else if (this.currentIndex === 1) {
      this.medicineTabPageRefreshKey++; // 触发用药Tab刷新
    } else if (this.currentIndex === 2) {
      this.profilePageRefreshKey++; // 触发我的Tab刷新
    }
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .width(24)
        .height(24)
        // .fillColor(this.currentIndex === targetIndex ? $r('app.color.primary') : '#9E9E9E')
      
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === targetIndex ? $r('app.color.primary') : '#9E9E9E')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        HomePage({ refreshKey: this.homePageRefreshKey })
      }
      .tabBar(this.TabBuilder('首页', 0, $r('app.media.home_selected'), $r('app.media.home')))

      TabContent() {
        MedicineTabPage({ refreshKey: this.medicineTabPageRefreshKey })
      }
      .tabBar(this.TabBuilder('用药', 1, $r('app.media.pill_selected'), $r('app.media.pill')))

      TabContent() {
        ProfilePage({ refreshKey: this.profilePageRefreshKey })
      }
      .tabBar(this.TabBuilder('我的', 2, $r('app.media.user_selected'), $r('app.media.user')))
    }
    .barMode(BarMode.Fixed)
    .barHeight(56)
    .barBackgroundColor('#FFFFFF')
    .width('100%')
    .height('100%')
    .onChange((index: number) => {
      const previousIndex = this.currentIndex;
      this.currentIndex = index;
      // Tab切换时，触发对应Tab的刷新
      if (index === 0 && previousIndex !== 0) {
        this.homePageRefreshKey++;
      } else if (index === 1 && previousIndex !== 1) {
        this.medicineTabPageRefreshKey++;
      } else if (index === 2 && previousIndex !== 2) {
        console.log('profilePageRefreshKey++')
        this.profilePageRefreshKey++;
      }
    })
  }
}


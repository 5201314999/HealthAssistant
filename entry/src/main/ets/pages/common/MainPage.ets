import { HomePage } from '../home/HomePage';
import { MedicineTabPage } from '../medicine/MedicineTabPage';
import { ProfilePage } from '../profile/ProfilePage';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  @State homePageRefreshKey: number = 0; // 刷新触发器

  // 页面显示时，如果当前是首页Tab，则触发刷新
  onPageShow() {
    console.log('MainPage onPageShow, currentIndex:', this.currentIndex);
    if (this.currentIndex === 0) {
      this.homePageRefreshKey++; // 触发刷新
    }
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === targetIndex ? $r('app.color.primary') : '#9E9E9E')
      
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
      .tabBar(this.TabBuilder('首页', 0, $r('app.media.home'), $r('app.media.home')))

      TabContent() {
        MedicineTabPage()
      }
      .tabBar(this.TabBuilder('用药', 1, $r('app.media.pill'), $r('app.media.pill')))

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.TabBuilder('我的', 2, $r('app.media.user'), $r('app.media.user')))
    }
    .barMode(BarMode.Fixed)
    .barHeight(56)
    .barBackgroundColor('#FFFFFF')
    .width('100%')
    .height('100%')
    .onChange((index: number) => {
      const previousIndex = this.currentIndex;
      this.currentIndex = index;
      // Tab切换时，如果切换到首页，触发刷新
      if (index === 0 && previousIndex !== 0) {
        this.homePageRefreshKey++;
      }
    })
  }
}


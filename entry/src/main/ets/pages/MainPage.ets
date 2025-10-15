import { HomePage } from './HomePage';
import { MedicineTabPage } from './MedicineTabPage';
import { ProfilePage } from './ProfilePage';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;

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
        HomePage()
      }
      .tabBar(this.TabBuilder('首页', 0, $r('app.media.heart'), $r('app.media.heart')))

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
      this.currentIndex = index;
    })
  }
}


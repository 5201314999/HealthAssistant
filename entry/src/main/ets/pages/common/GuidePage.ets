import router from '@ohos.router';

/**
 * 新手引导页面（占位）
 * TODO: 后续实现引导内容
 */
@Entry
@Component
struct GuidePage {
  build() {
    Column() {
      Text('新手引导')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100 })

      Text('引导内容待实现...')
        .fontSize(16)
        .fontColor('#9E9E9E')
        .margin({ top: 20 })

      Button('进入应用')
        .width('80%')
        .height(50)
        .backgroundColor('#4CAF50')
        .margin({ top: 50 })
        .onClick(() => {
          router.replaceUrl({ url: 'pages/home/Index' });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
  }
}


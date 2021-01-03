# Banner

适用于常规场景的banner，可构建于纯代码、storyboard、xib，可使用autoLayout、frame布局

图片缓存于
`NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] + "/com.zhouwk.banners/"`

![Banner.png](Banner.png)

# 样式

* 默认样式

    ![preview-a](preview-a.gif)

* 设置间距
    ```
    banner.config(itemsHorizontalMargin: 10, preloadEdge: 10, cornerRadius: 10)
    ```
    ![preview-b](preview-b.gif)

* 设置间距和缩放系数
    ```
    banner.config(itemsHorizontalMargin: 10, preloadEdge: 10, zoom: 0.9, cornerRadius: 10)
    ```
    ![preview-cc](preview-c.gif)
    
    
# Installation

```
支持Swift Package Manager
```
    

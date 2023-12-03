# Common-Shader-Unity-
Common Shader（自用常备shader）
- 1、charactor shader是通用NPR-PBR混合shader（Attention：在hair cast选项中根据自己的需要设置合适的stencil模板测试值）
- 2、VOlight、Fog shader可以提供体积光、雾气效果，使用前请先在RenderFeature里设置好对应的RenderFeature脚本！
  - 2.1  如果出现黑屏等不正常的情况，确认你配置好renderfeature及shader后播放游戏或者重启unity即可正常。
- 3、grass shader如果开启Disturb请启用对应的C#脚本以传入角色世界位置坐标

import 'package:flutter/material.dart';
import 'package:xui_flutter/core/data/core_data.dart';
import 'package:xui_flutter/core/widget/cw_factory.dart';
import 'package:xui_flutter/designer/application_manager.dart';
import 'package:xui_flutter/designer/builder/form_builder.dart';

import '../../core/data/core_repository.dart';
import '../../core/widget/cw_core_loader.dart';
import '../../core/widget/cw_core_styledbox.dart';
import '../../core/widget/cw_core_widget.dart';
import '../../widget/cw_selector.dart';
import '../designer.dart';
import '../designer_selector_properties.dart';
import '../widget/widget_tab.dart';
import 'prop_builder.dart';

class StyleBuilder {
  List<Widget> listStyle = [];

  void buildWidgetProperties(CWWidgetCtx aCtx, int buttonId) {
    State? state = CoreDesigner.of().styleKey.currentState;

    bool ok = true;

    // ignore: dead_code
    if (ok || state != null) {
      listStyle.clear();
      var app = CWApplication.of();

      if (aCtx.getWidgetInSlot() == null) {
        // ignore: invalid_use_of_protected_member
        state?.setState(() {});
        return;
      }

      aCtx = aCtx.getWidgetInSlot()!.ctx;
      CoreDataEntity? designEntity = aCtx.designEntity;
      if (designEntity?.operation == CDAction.inherit) {
        designEntity?.operation = CDAction.read;
      }

      DesignCtx dCtx = DesignCtx().forDesign(aCtx);

      designEntity ??= PropBuilder.getEmptyEntity(aCtx.loader, dCtx);
      dCtx.designEntity = designEntity;

      addHeader(dCtx);

      Map<String, dynamic>? aStyle = aCtx.designEntity?.value[iDStyle];
      CoreDataEntity styleEntity;
      if (aStyle == null) {
        styleEntity = app.collection.createEntityByJson('StyleModel', {});
      } else {
        styleEntity = app.collection.createEntityByJson('StyleModel', aStyle);
        styleEntity.operation = CDAction.read;
      }

      var provider = CWRepository('styleProvider', styleEntity.type,
          CWRepositoryDataSelector.noLoader())
        ..addContent(styleEntity);

      provider.addAction(CWRepositoryAction.onValueChanged,
          MapDesignStyle(dCtx, designEntity, styleEntity));
      provider.addAction(
          CWRepositoryAction.onValueChanged, RefreshDesign(dCtx));

      //------------------------------------------------------------------
      initAlignment(aCtx, provider);
      initMargin(aCtx, provider);
      initBorder(aCtx, provider);
      initBackground(aCtx, provider);
      initPadding(aCtx, provider);
      initText(aCtx, provider);

      // ignore: invalid_use_of_protected_member
      state?.setState(() {});
    }
  }

  void addHeader(DesignCtx aCtx) {
    String name =
        CWWidgetCollectionBuilder.getWidgetName(aCtx.designEntity!.type);

    listStyle.add(Container(
      width: double.infinity,
      height: 30,
      color: Colors.deepOrange.shade300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Center(
            child: Text(
                style: const TextStyle(color: Colors.black), 'Style of $name')),
      ),
    ));
  }

  void initMargin(CWWidgetCtx ctx, CWRepository provider) {
    CWAppLoaderCtx ctxLoader = CWAppLoaderCtx().from(ctx.loader);
    ctxLoader.addRepository(provider);

    AttrFormLoader loader =
        AttrFormLoader('rootBody0', ctxLoader, 'Margin', provider, true, mode: ModeForm.expand);

    CoreDataAttribut attr = CoreDataAttribut('ptop')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'top')
        .addCustomValue('icon', Icons.expand_less)
        .addCustomValue('min', 0)
        .addCustomValue('max', 50);
    loader.addAttr(attr);
    attr = CoreDataAttribut('pbottom')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'bottom')
        .addCustomValue('icon', Icons.expand_more)
        .addCustomValue('min', 0)
        .addCustomValue('max', 50);
    loader.addAttr(attr);
    attr = CoreDataAttribut('pleft')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'left')
        .addCustomValue('icon', Icons.chevron_left)
        .addCustomValue('min', 0)
        .addCustomValue('max', 50);
    loader.addAttr(attr);
    attr = CoreDataAttribut('pright')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'right')
        .addCustomValue('icon', Icons.chevron_right)
        .addCustomValue('min', 0)
        .addCustomValue('max', 50);
    loader.addAttr(attr);

    listStyle.add(loader.getWidget('root', 'root'));
  }

  void initPadding(CWWidgetCtx ctx, CWRepository provider) {
    CWAppLoaderCtx ctxLoader = CWAppLoaderCtx().from(ctx.loader);
    ctxLoader.addRepository(provider);

    AttrFormLoader loader =
        AttrFormLoader('rootBody0', ctxLoader, 'Padding', provider, true, mode: ModeForm.expand);

    CoreDataAttribut attr = CoreDataAttribut('mtop')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'top')
        .addCustomValue('icon', Icons.arrow_upward_rounded)
        .addCustomValue('min', 0)
        .addCustomValue('max', 50);
    loader.addAttr(attr);
    attr = CoreDataAttribut('mbottom')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'bottom')
        .addCustomValue('icon', Icons.arrow_downward_rounded)
        .addCustomValue('min', 0)
        .addCustomValue('max', 50);
    loader.addAttr(attr);
    attr = CoreDataAttribut('mleft')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'left')
        .addCustomValue('icon', Icons.west_rounded)
        .addCustomValue('min', 0)
        .addCustomValue('max', 50);
    loader.addAttr(attr);
    attr = CoreDataAttribut('mright')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'right')
        .addCustomValue('icon', Icons.east_rounded)
        .addCustomValue('min', 0)
        .addCustomValue('max', 50);
    loader.addAttr(attr);

    listStyle.add(loader.getWidget('root', 'root'));
  }

  void initBorder(CWWidgetCtx ctx, CWRepository provider) {
    CWAppLoaderCtx ctxLoader = CWAppLoaderCtx().from(ctx.loader);
    ctxLoader.addRepository(provider);

    AttrFormLoader loader = AttrFormLoader(
        'rootBody0', ctxLoader, 'Border & Elevation', provider, true, mode: ModeForm.expand);

    CoreDataAttribut attr = CoreDataAttribut('elevation')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'elevation')
        .addCustomValue('icon', Icons.copy_all_rounded)
        .addCustomValue('min', 0)
        .addCustomValue('max', 20);
    loader.addAttr(attr);

    attr = CoreDataAttribut('bSize')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'border size')
        .addCustomValue('icon', Icons.highlight_alt_rounded)
        .addCustomValue('min', 0)
        .addCustomValue('max', 20);
    loader.addAttr(attr);

    attr = CoreDataAttribut('bRadius')
        .init(CDAttributType.int,
            tName: CWSelectorType.slider.name, aLabel: 'b. radius')
        .addCustomValue('icon', Icons.panorama_wide_angle_rounded)
        .addCustomValue('min', 0)
        .addCustomValue('max', 20);
    loader.addAttr(attr);

    attr = CoreDataAttribut('bColor')
        .init(CDAttributType.one,
            tName: CWSelectorType.color.name, aLabel: 'border color')
        .addCustomValue('icon', Icons.border_color_rounded);
    loader.addAttr(attr);

    listStyle.add(loader.getWidget('root', 'root'));
  }

  void initAlignment(CWWidgetCtx ctx, CWRepository provider) {
    CWAppLoaderCtx ctxLoader = CWAppLoaderCtx().from(ctx.loader);
    ctxLoader.addRepository(provider);

    AttrFormLoader loader =
        AttrFormLoader('rootBody0', ctxLoader, 'Alignment', provider, true, mode: ModeForm.expand);

    List listAxis = [
      {'icon': Icons.align_vertical_top, 'value': -1},
      {'icon': Icons.align_vertical_center, 'value': 0},
      {'icon': Icons.align_vertical_bottom, 'value': 1},
    ];

    List listCross = [
      {'icon': Icons.align_horizontal_left, 'value': -1},
      {'icon': Icons.align_horizontal_center, 'value': 0},
      {'icon': Icons.align_horizontal_right, 'value': 1},
    ];

    CoreDataAttribut attr = CoreDataAttribut('boxAlignVertical')
        .init(CDAttributType.text, tName: 'toogle', aLabel: 'Box align H.')
        .addCustomValue('bindValue', listAxis);
    loader.addAttr(attr);
    attr = CoreDataAttribut('boxAlignHorizontal')
        .init(CDAttributType.text, tName: 'toogle', aLabel: 'Box align V.')
        .addCustomValue('bindValue', listCross);
    loader.addAttr(attr);

    listStyle.add(loader.getWidget('root', 'root'));
  }

  void initBackground(CWWidgetCtx ctx, CWRepository provider) {
    CWAppLoaderCtx ctxLoader = CWAppLoaderCtx().from(ctx.loader);
    ctxLoader.addRepository(provider);

    AttrFormLoader loader = AttrFormLoader(
        'root', ctxLoader, 'Background', provider, true,
        mode: ModeForm.column);

    CoreDataAttribut attr = CoreDataAttribut('bgColor')
        .init(CDAttributType.one,
            tName: CWSelectorType.color.name, aLabel: 'bg color')
        .addCustomValue('icon', Icons.format_color_fill);
    loader.addAttr(attr);

    // var tab = Container(height: 150, child :WidgetTab(autoHeight: true, heightTab: 40, listTab: const [
    //   Tab(text: 'standard'),
    //   Tab(text: 'gradient'),
    // ], listTabCont: [
    //   loader.getWidget('root', 'root'),
    //   Container(),
    // ]));

    var tab = WidgetTab(autoHeight: true, heightTab: 40, listTab: const [
      Tab(text: 'Background'),
      Tab(text: 'Gradient'),
    ], listTabCont: [
      loader.getWidget('root', 'root'),
      Container(),
    ]);

    listStyle.add(tab);
  }

  void initText(CWWidgetCtx ctx, CWRepository provider) {
    CWAppLoaderCtx ctxLoader = CWAppLoaderCtx().from(ctx.loader);
    ctxLoader.addRepository(provider);

    AttrFormLoader loader =
        AttrFormLoader('rootBody0', ctxLoader, 'Text', provider, true, mode: ModeForm.expand);

    List listCross = [
      {'icon': Icons.align_horizontal_left, 'value': 'start'},
      {'icon': Icons.align_horizontal_center, 'value': 'center'},
      {'icon': Icons.align_horizontal_right, 'value': 'end'},
    ];

    CoreDataAttribut attr = CoreDataAttribut('text align')
        .init(CDAttributType.text, tName: 'toogle')
        .addCustomValue('bindValue', listCross);
    loader.addAttr(attr);

    attr = CoreDataAttribut('tColor')
        .init(CDAttributType.one,
            tName: CWSelectorType.color.name, aLabel: 'text color')
        .addCustomValue('icon', Icons.format_color_text_rounded);
    loader.addAttr(attr);

    List listTextType = [
      {'icon': Icons.format_bold, 'value': 'bold'},
      {'icon': Icons.format_italic, 'value': 'italic'},
      {'icon': Icons.format_underline, 'value': 'underline'},
      {'icon': Icons.format_strikethrough, 'value': 'lineThrough'},
      {'icon': Icons.format_overline, 'value': 'overline'},
    ];
    attr = CoreDataAttribut('text style')
        .init(CDAttributType.text, tName: 'toogle')
        .addCustomValue('bindValue', listTextType);
    loader.addAttr(attr);

    listStyle.add(loader.getWidget('root', 'root'));

    // Text('\$8.99',
    //     style: TextStyle(
    //         color: Colors.grey[800],
    //         fontWeight: FontWeight.bold,
    //         fontStyle: FontStyle.italic,
    //         fontSize: 40,
    //         decoration: TextDecoration.lineThrough));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_example/chat-app/providers/vault_setting_controller.dart';
import 'package:flutter_example/chat-app/widgets/option_input.dart';
import 'package:flutter_example/chat-app/utils/AIHandler.dart';
import 'package:get/get.dart';
import '../../models/api_model.dart';

class ApiEditPage extends StatefulWidget {
  final ApiModel? api;

  const ApiEditPage({Key? key, this.api}) : super(key: key);

  @override
  State<ApiEditPage> createState() => _ApiEditPageState();
}

class _ApiEditPageState extends State<ApiEditPage> {
  final _formKey = GlobalKey<FormState>();
  final VaultSettingController controller = Get.find();

  String modelName = "";
  bool _isLoadingModels = false;
  List<String> _availableModels = [];

  late TextEditingController _apiKeyController;
  //late TextEditingController _modelNameController;
  late TextEditingController _urlController;
  late TextEditingController _remarksController;
  late TextEditingController _displayNameController;
  late ServiceProvider _selectedProvider;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.api?.apiKey ?? '');
    modelName = widget.api?.modelName ?? '';
    _urlController = TextEditingController(text: widget.api?.url ?? '');
    _remarksController = TextEditingController(text: widget.api?.remarks ?? '');
    _displayNameController =
        TextEditingController(text: widget.api?.displayName ?? '');

    _selectedProvider = widget.api?.provider ?? ServiceProvider.openai;
    _availableModels = List.from(_selectedProvider.modelList);
  }

  /// 获取模型列表
  Future<void> _fetchModelList() async {
    if (_apiKeyController.text.isEmpty) {
      Get.snackbar('错误', '请先填写API Key', 
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.red);
      return;
    }

    String url;
    if (_selectedProvider.isCustom) {
      if (_urlController.text.isEmpty) {
        Get.snackbar('错误', '请先填写URL', 
            snackPosition: SnackPosition.BOTTOM,
            colorText: Colors.red);
        return;
      }
      url = _urlController.text;
    } else {
      url = _selectedProvider.defaultUrl;
    }

    setState(() {
      _isLoadingModels = true;
    });

    try {
      final models = await Aihandler.fetchModelList(
        url,
        _apiKeyController.text,
        _selectedProvider,
        (isSuccess, message) {
          if (!isSuccess) {
            Get.snackbar('获取模型列表失败', message,
                snackPosition: SnackPosition.BOTTOM,
                colorText: Colors.red);
          } else {
            Get.snackbar('成功', message,
                snackPosition: SnackPosition.BOTTOM,
                colorText: Colors.green);
          }
        },
      );

      if (models.isNotEmpty) {
        setState(() {
          _availableModels = models;
        });
      }
    } finally {
      setState(() {
        _isLoadingModels = false;
      });
    }
  }

  /// 获取当前可用的模型列表（预设 + 获取的）
  List<String> _getCurrentModelList() {
    final presetModels = _selectedProvider.modelList;
    final allModels = <String>{...presetModels, ..._availableModels}.toList();
    return allModels;
  }

  /// 当API Key和URL都填写完成时自动获取模型列表
  void _autoFetchModelsIfReady() {
    // 避免重复请求
    if (_isLoadingModels) return;
    
    // 检查条件是否满足
    bool canFetch = _apiKeyController.text.isNotEmpty;
    if (_selectedProvider.isCustom) {
      canFetch = canFetch && _urlController.text.isNotEmpty;
    }
    
    if (canFetch) {
      // 延迟一点时间，避免用户输入过程中频繁请求
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted && !_isLoadingModels) {
          _fetchModelList();
        }
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    // _modelNameController.dispose();
    _urlController.dispose();
    _remarksController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _saveApi() async {
    if (_formKey.currentState!.validate()) {
      final api = ApiModel(
        id: widget.api?.id ?? DateTime.now().millisecondsSinceEpoch,
        apiKey: _apiKeyController.text,
        displayName: _displayNameController.text,
        modelName: modelName,
        url: _selectedProvider.defaultUrl.isEmpty
            ? _urlController.text
            : _selectedProvider.defaultUrl,
        provider: _selectedProvider,
        remarks: _remarksController.text,
      );

      if (widget.api == null) {
        await controller.addApi(api);
      } else {
        await controller.updateApi(api);
      }

      Get.back(result: api);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.api == null ? '新建 API' : '编辑 API'),
        actions: widget.api != null
            ? [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _duplicateApi,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteConfirmDialog(context),
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DropdownButtonFormField<ServiceProvider>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: '服务商',
              ),
              items: ServiceProvider.values
                  .map((provider) => DropdownMenuItem(
                        value: provider,
                        child: Text(provider.toLocalString()),
                      ))
                  .toList(),
              onChanged: (ServiceProvider? value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                    _availableModels = List.from(_selectedProvider.modelList);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apiKeyController,
              obscureText: false,
              decoration: const InputDecoration(
                labelText: 'API Key',
                // suffixIcon: Icon(Icons.visibility_off),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 API Key';
                }
                return null;
              },
              onChanged: (value) {
                // API Key变化时，如果URL也已填写，则自动获取模型列表
                _autoFetchModelsIfReady();
              },
            ),
            const SizedBox(height: 16),
            CustomOptionInputWidget.fromStringOptions(
              options: _getCurrentModelList(),
              labelText: "模型名称",
              initialValue: modelName,
              onChanged: (value) {
                final oldval = modelName;
                modelName = value;
                if (_displayNameController.text.isEmpty ||
                    _displayNameController.text == oldval) {
                  _displayNameController.text = value;
                }
              },
            ),
            const SizedBox(height: 8),
            // 获取模型列表按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingModels ? null : _fetchModelList,
                    icon: _isLoadingModels 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh),
                    label: Text(_isLoadingModels ? '获取中...' : '获取模型列表'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedProvider.defaultUrl.isEmpty)
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入 URL';
                  }
                  return null;
                },
                onChanged: (value) {
                  // URL变化时，如果API Key也已填写，则自动获取模型列表
                  _autoFetchModelsIfReady();
                },
              ),
            Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: '显示名称(选填)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: '备注(选填)',
              ),
              maxLines: 3,
            ),
            Divider(),
            // ElevatedButton.icon(
            //     onPressed: () {
            //       Aihandler.testConnectivity(
            //           _urlController.text
            //               .replaceAll('/v1/chat/completions', '')
            //               .replaceAll('/chat/completions', ''),
            //           (isSuccess, message) {
            //         Get.snackbar(isSuccess ? '成功' : '失败', message,
            //             snackPosition: SnackPosition.BOTTOM,
            //             colorText: isSuccess ? Colors.green : Colors.red);
            //       });
            //     },
            //     label: Text('测试连通性'))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveApi,
        child: const Icon(Icons.save),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这个 API 吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.deleteApi(
                  id: widget.api!.id,
                );
                Get.back();
              },
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _duplicateApi() async {
    final newApi = ApiModel(
      id: DateTime.now().millisecondsSinceEpoch,
      apiKey: _apiKeyController.text,
      displayName: "${_displayNameController.text} (复制)",
      modelName: modelName,
      url: _selectedProvider.defaultUrl.isEmpty
          ? _urlController.text
          : _selectedProvider.defaultUrl,
      provider: _selectedProvider,
      remarks: _remarksController.text,
    );

    await controller.addApi(newApi);
    Get.back();
  }
}

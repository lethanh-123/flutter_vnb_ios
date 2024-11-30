import 'branch_stock.dart'; // Import BranchStock class

class ProductTonKho {
  final String name;
  final String size;
  final String thumb;
  final int stockQuantity;
  final int price;
  final List<BranchStock> branchStockList;

  ProductTonKho({
    required this.name,
    required this.size,
    required this.thumb,
    required this.stockQuantity,
    required this.price,
    required this.branchStockList,
  });

  factory ProductTonKho.fromJson(Map<String, dynamic> json) {
    var branchList = (json['cn_list'] as List)
        .map((branchJson) => BranchStock.fromJson(branchJson))
        .toList();

    return ProductTonKho(
      name: json['ten_sp'],
      size: json['size'],
      thumb: json['thumb'],
      stockQuantity: json['total'],
      price: json['gia'],
      branchStockList: branchList,
    );
  }
}

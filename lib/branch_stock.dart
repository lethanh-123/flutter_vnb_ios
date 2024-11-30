class BranchStock {
  final String branchName;
  final int stockQuantity;

  BranchStock({required this.branchName, required this.stockQuantity});

  factory BranchStock.fromJson(Map<String, dynamic> json) {
    return BranchStock(
      branchName: json['ten'],
      stockQuantity: json['ton_kho'],
    );
  }
}

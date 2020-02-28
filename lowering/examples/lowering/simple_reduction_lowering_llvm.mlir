module {
  llvm.func @malloc(!llvm.i64) -> !llvm<"i8*">
  llvm.func @riseFun() -> !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }"> {
    %0 = llvm.mlir.constant(5.000000e+00 : f32) : !llvm.float
    %1 = llvm.mlir.constant(0.000000e+00 : f32) : !llvm.float
    %2 = llvm.mlir.constant(0 : index) : !llvm.i64
    %3 = llvm.mlir.constant(4 : index) : !llvm.i64
    %4 = llvm.mlir.constant(1 : index) : !llvm.i64
    %5 = llvm.mlir.constant(4 : index) : !llvm.i64
    %6 = llvm.mlir.null : !llvm<"float*">
    %7 = llvm.mlir.constant(1 : index) : !llvm.i64
    %8 = llvm.getelementptr %6[%7] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    %9 = llvm.ptrtoint %8 : !llvm<"float*"> to !llvm.i64
    %10 = llvm.mul %5, %9 : !llvm.i64
    %11 = llvm.call @malloc(%10) : (!llvm.i64) -> !llvm<"i8*">
    %12 = llvm.bitcast %11 : !llvm<"i8*"> to !llvm<"float*">
    %13 = llvm.mlir.undef : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %14 = llvm.insertvalue %12, %13[0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %15 = llvm.insertvalue %12, %14[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %16 = llvm.mlir.constant(0 : index) : !llvm.i64
    %17 = llvm.insertvalue %16, %15[2] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %18 = llvm.mlir.constant(1 : index) : !llvm.i64
    %19 = llvm.insertvalue %5, %17[3, 0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %20 = llvm.insertvalue %18, %19[4, 0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    llvm.br ^bb1(%2 : !llvm.i64)
  ^bb1(%21: !llvm.i64):	// 2 preds: ^bb0, ^bb2
    %22 = llvm.icmp "slt" %21, %3 : !llvm.i64
    llvm.cond_br %22, ^bb2, ^bb3
  ^bb2:	// pred: ^bb1
    %23 = llvm.extractvalue %20[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %24 = llvm.mlir.constant(0 : index) : !llvm.i64
    %25 = llvm.mlir.constant(1 : index) : !llvm.i64
    %26 = llvm.mul %21, %25 : !llvm.i64
    %27 = llvm.add %24, %26 : !llvm.i64
    %28 = llvm.getelementptr %23[%27] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    llvm.store %0, %28 : !llvm<"float*">
    %29 = llvm.add %21, %4 : !llvm.i64
    llvm.br ^bb1(%29 : !llvm.i64)
  ^bb3:	// pred: ^bb1
    %30 = llvm.mlir.constant(1 : index) : !llvm.i64
    %31 = llvm.mlir.null : !llvm<"float*">
    %32 = llvm.mlir.constant(1 : index) : !llvm.i64
    %33 = llvm.getelementptr %31[%32] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    %34 = llvm.ptrtoint %33 : !llvm<"float*"> to !llvm.i64
    %35 = llvm.mul %30, %34 : !llvm.i64
    %36 = llvm.call @malloc(%35) : (!llvm.i64) -> !llvm<"i8*">
    %37 = llvm.bitcast %36 : !llvm<"i8*"> to !llvm<"float*">
    %38 = llvm.mlir.undef : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %39 = llvm.insertvalue %37, %38[0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %40 = llvm.insertvalue %37, %39[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %41 = llvm.mlir.constant(0 : index) : !llvm.i64
    %42 = llvm.insertvalue %41, %40[2] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %43 = llvm.mlir.constant(1 : index) : !llvm.i64
    %44 = llvm.insertvalue %30, %42[3, 0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %45 = llvm.insertvalue %43, %44[4, 0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    llvm.br ^bb4(%2 : !llvm.i64)
  ^bb4(%46: !llvm.i64):	// 2 preds: ^bb3, ^bb5
    %47 = llvm.icmp "slt" %46, %4 : !llvm.i64
    llvm.cond_br %47, ^bb5, ^bb6
  ^bb5:	// pred: ^bb4
    %48 = llvm.extractvalue %45[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %49 = llvm.mlir.constant(0 : index) : !llvm.i64
    %50 = llvm.mlir.constant(1 : index) : !llvm.i64
    %51 = llvm.mul %46, %50 : !llvm.i64
    %52 = llvm.add %49, %51 : !llvm.i64
    %53 = llvm.getelementptr %48[%52] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    llvm.store %1, %53 : !llvm<"float*">
    %54 = llvm.add %46, %4 : !llvm.i64
    llvm.br ^bb4(%54 : !llvm.i64)
  ^bb6:	// pred: ^bb4
    llvm.br ^bb7(%2 : !llvm.i64)
  ^bb7(%55: !llvm.i64):	// 2 preds: ^bb6, ^bb8
    %56 = llvm.icmp "slt" %55, %3 : !llvm.i64
    llvm.cond_br %56, ^bb8, ^bb9
  ^bb8:	// pred: ^bb7
    %57 = llvm.extractvalue %45[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %58 = llvm.mlir.constant(0 : index) : !llvm.i64
    %59 = llvm.mlir.constant(1 : index) : !llvm.i64
    %60 = llvm.mul %2, %59 : !llvm.i64
    %61 = llvm.add %58, %60 : !llvm.i64
    %62 = llvm.getelementptr %57[%61] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    %63 = llvm.load %62 : !llvm<"float*">
    %64 = llvm.extractvalue %20[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %65 = llvm.mlir.constant(0 : index) : !llvm.i64
    %66 = llvm.mlir.constant(1 : index) : !llvm.i64
    %67 = llvm.mul %55, %66 : !llvm.i64
    %68 = llvm.add %65, %67 : !llvm.i64
    %69 = llvm.getelementptr %64[%68] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    %70 = llvm.load %69 : !llvm<"float*">
    %71 = llvm.fadd %63, %70 : !llvm.float
    %72 = llvm.extractvalue %45[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %73 = llvm.mlir.constant(0 : index) : !llvm.i64
    %74 = llvm.mlir.constant(1 : index) : !llvm.i64
    %75 = llvm.mul %2, %74 : !llvm.i64
    %76 = llvm.add %73, %75 : !llvm.i64
    %77 = llvm.getelementptr %72[%76] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    llvm.store %71, %77 : !llvm<"float*">
    %78 = llvm.add %55, %4 : !llvm.i64
    llvm.br ^bb7(%78 : !llvm.i64)
  ^bb9:	// pred: ^bb7
    llvm.return %45 : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
  }
  llvm.func @print_memref_f32(!llvm.i64, !llvm<"i8*">)
  llvm.func @simple_reduction() {
    %0 = llvm.call @riseFun() : () -> !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %1 = llvm.mlir.constant(1 : index) : !llvm.i64
    %2 = llvm.alloca %1 x !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }"> : (!llvm.i64) -> !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }*">
    llvm.store %0, %2 : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }*">
    %3 = llvm.bitcast %2 : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }*"> to !llvm<"i8*">
    %4 = llvm.mlir.constant(1 : i64) : !llvm.i64
    %5 = llvm.mlir.undef : !llvm<"{ i64, i8* }">
    %6 = llvm.insertvalue %4, %5[0] : !llvm<"{ i64, i8* }">
    %7 = llvm.insertvalue %3, %6[1] : !llvm<"{ i64, i8* }">
    %8 = llvm.extractvalue %7[0] : !llvm<"{ i64, i8* }">
    %9 = llvm.extractvalue %7[1] : !llvm<"{ i64, i8* }">
    llvm.call @print_memref_f32(%8, %9) : (!llvm.i64, !llvm<"i8*">) -> ()
    llvm.return
  }
}

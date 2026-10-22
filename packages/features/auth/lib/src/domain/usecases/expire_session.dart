import 'package:architecture/architecture.dart';
import 'package:injectable/injectable.dart';

import '../repositories/auth_repository.dart';

@injectable
class ExpireSessionUseCase extends NoParamUseCase<void> {
  const ExpireSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call([NoParams param = noParams]) =>
      runResultGuarded(_repository.expireSession);
}

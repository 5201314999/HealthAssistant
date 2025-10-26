export class ErrorUtils {
  /**
   * 将任意类型错误转换为标准的Error对象
   * @param err 原始错误对象（支持任意类型）
   */
  static toError(err: Object): Error {
    if (err instanceof Error) {
      return err;
    }
    return new Error(err?.toString() ?? "Unknown error");
  }
}
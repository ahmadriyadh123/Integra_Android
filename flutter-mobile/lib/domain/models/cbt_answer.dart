/// A student's answer to one CBT question, independent of the API payload.
class CbtAnswer {
  final int questionId;
  final int? selectedOptionId;
  final String questionType;

  const CbtAnswer({
    required this.questionId,
    required this.selectedOptionId,
    required this.questionType,
  });
}

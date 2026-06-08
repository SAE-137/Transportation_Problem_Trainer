#include "recalculationsolver.h"

QVector<QVector<QString>> RecalculationSolver::makeStringMatrix(int rows, int cols) const
{
    return QVector<QVector<QString>>(rows, QVector<QString>(cols, ""));
}

RecalculationResult RecalculationSolver::solve(const TransportProblemState& source,
                                               const QVector<QVector<QString>>& currentLoadMatrix,
                                               const QVector<QPair<int, int>>& cyclePath) const
{
    RecalculationResult result;

    const int rows = source.rows();
    const int cols = source.cols();

    if (rows <= 0 || cols <= 0) {
        result.message = "Ошибка: пустая задача для пересчёта плана.";
        return result;
    }

    if (currentLoadMatrix.size() != rows) {
        result.message = "Ошибка: матрица перевозок имеет неверное число строк.";
        return result;
    }

    for (const auto& row : currentLoadMatrix) {
        if (row.size() != cols) {
            result.message = "Ошибка: матрица перевозок имеет неверное число столбцов.";
            return result;
        }
    }

    if (cyclePath.size() < 5) {
        result.message = "Ошибка: цикл пересчёта слишком короткий.";
        return result;
    }

    const QVector<QVector<int>> costs = source.costMatrix();
    const QVector<int> supply = source.supply();
    const QVector<int> demand = source.demand();

    result.cyclePath = cyclePath;

    QVector<QVector<QString>> cycleMarks = makeStringMatrix(rows, cols);

    const int startRow = cyclePath[0].first;
    const int startCol = cyclePath[0].second;
    cycleMarks[startRow][startCol] = "r";

    QString minusText = "Клетки со знаком '-' и их перевозки:\n";

    int rValue = -1;
    int leavingRow = -1;
    int leavingCol = -1;

    for (int i = 1; i < cyclePath.size() - 1; ++i) {
        const int r = cyclePath[i].first;
        const int c = cyclePath[i].second;

        if (i % 2 == 1) {
            cycleMarks[r][c] = "-";

            bool ok = false;
            const int value = currentLoadMatrix[r][c].trimmed().toInt(&ok);
            if (!ok) {
                result.message = "Ошибка: в клетке со знаком '-' нет корректной перевозки.";
                return result;
            }

            minusText += QString("(B%1, A%2) = %3\n")
                             .arg(r + 1)
                             .arg(c + 1)
                             .arg(value);

            if (rValue == -1 || value < rValue) {
                rValue = value;
                leavingRow = r;
                leavingCol = c;
            }
        } else {
            cycleMarks[r][c] = "+";
        }
    }

    if (rValue < 0) {
        result.message = "Ошибка: не удалось вычислить r.";
        return result;
    }

    QString rCalc =
        minusText +
        QString("\nБерём минимум среди клеток со знаком '-':\n"
                "r = %1\n"
                "Удаляемой клеткой выбираем (B%2, A%3), так как именно в ней достигается минимум.")
            .arg(rValue)
            .arg(leavingRow + 1)
            .arg(leavingCol + 1);

    {
        RecalculationStep step;
        step.title = "Вычисление r";
        step.description = "Значение r выбирается как минимальная перевозка среди клеток цикла со знаком '-'.";
        step.calculationText = rCalc;

        step.costMatrix = costs;
        step.supply = supply;
        step.demand = demand;
        step.loadMatrix = currentLoadMatrix;
        step.markMatrix = cycleMarks;
        step.selectedRow = leavingRow;
        step.selectedCol = leavingCol;

        result.steps.push_back(step);
    }

    QVector<QVector<QString>> newLoadMatrix = currentLoadMatrix;
    QString recalcText = "Выполним пересчёт плана по циклу:\n";

    bool leavingCellRemoved = false;

    for (int i = 0; i < cyclePath.size() - 1; ++i) {
        const int r = cyclePath[i].first;
        const int c = cyclePath[i].second;

        QString oldStr = newLoadMatrix[r][c].trimmed();
        int oldValue = oldStr.isEmpty() ? 0 : oldStr.toInt();

        if (i % 2 == 0) {
            const int newValue = oldValue + rValue;
            newLoadMatrix[r][c] = QString::number(newValue);

            if (i == 0) {
                recalcText += QString("(B%1, A%2): 0 + %3 = %4\n")
                .arg(r + 1)
                    .arg(c + 1)
                    .arg(rValue)
                    .arg(newValue);
            } else {
                recalcText += QString("(B%1, A%2): %3 + %4 = %5\n")
                .arg(r + 1)
                    .arg(c + 1)
                    .arg(oldValue)
                    .arg(rValue)
                    .arg(newValue);
            }
        } else {
            const int newValue = oldValue - rValue;

            if (newValue < 0) {
                result.message = "Ошибка: после пересчёта получена отрицательная перевозка.";
                return result;
            }

            if (newValue == 0) {
                if (!leavingCellRemoved && r == leavingRow && c == leavingCol) {
                    newLoadMatrix[r][c] = "";
                    leavingCellRemoved = true;
                    recalcText += QString("(B%1, A%2): %3 - %4 = 0, клетка удаляется из базиса\n")
                                      .arg(r + 1)
                                      .arg(c + 1)
                                      .arg(oldValue)
                                      .arg(rValue);
                } else {
                    newLoadMatrix[r][c] = "0";
                    recalcText += QString("(B%1, A%2): %3 - %4 = 0\n")
                                      .arg(r + 1)
                                      .arg(c + 1)
                                      .arg(oldValue)
                                      .arg(rValue);
                }
            } else {
                newLoadMatrix[r][c] = QString::number(newValue);
                recalcText += QString("(B%1, A%2): %3 - %4 = %5\n")
                                  .arg(r + 1)
                                  .arg(c + 1)
                                  .arg(oldValue)
                                  .arg(rValue)
                                  .arg(newValue);
            }
        }
    }

    QVector<QVector<QString>> finalMarks = makeStringMatrix(rows, cols);
    finalMarks[leavingRow][leavingCol] = "del";

    {
        RecalculationStep step;
        step.title = "Пересчёт плана";
        step.description = "После вычисления r пересчитываем перевозки по знакам '+' и '-'.";
        step.calculationText = recalcText;

        step.costMatrix = costs;
        step.supply = supply;
        step.demand = demand;
        step.loadMatrix = newLoadMatrix;
        step.markMatrix = finalMarks;
        step.selectedRow = leavingRow;
        step.selectedCol = leavingCol;

        result.steps.push_back(step);
    }

    result.valid = true;
    result.message = "Пересчёт плана завершён.";
    result.rValue = rValue;
    result.leavingRow = leavingRow;
    result.leavingCol = leavingCol;
    result.newLoadMatrix = newLoadMatrix;

    return result;
}

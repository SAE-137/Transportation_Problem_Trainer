#ifndef CYCLESOLVER_H
#define CYCLESOLVER_H

#pragma once

#include <QString>
#include <QVector>
#include <QPair>

#include "transportproblemstate.h"

struct CycleStep
{
    QString title;
    QString description;
    QString calculationText;

    QVector<QVector<int>> costMatrix;
    QVector<int> supply;
    QVector<int> demand;

    QVector<QVector<QString>> loadMatrix;
    QVector<QVector<QString>> markMatrix;

    int selectedRow = -1;
    int selectedCol = -1;
};

struct CycleResult
{
    bool valid = false;
    QString message;

    QVector<CycleStep> steps;

    QVector<QPair<int, int>> cyclePath;   // путь с повтором стартовой клетки в конце
    QVector<QPair<int, int>> minusCells;  // клетки со знаком "-"
};

class CycleSolver
{
public:
    CycleResult solve(const TransportProblemState& source,
                      const QVector<QVector<QString>>& loadMatrix,
                      int enterRow,
                      int enterCol) const;

private:
    QVector<QVector<QString>> makeStringMatrix(int rows, int cols) const;

    bool findCycle(const QVector<QVector<bool>>& allowed,
                   int startRow,
                   int startCol,
                   QVector<QPair<int, int>>& outPath) const;

    bool dfs(const QVector<QVector<bool>>& allowed,
             int startRow,
             int startCol,
             QVector<QPair<int, int>>& path,
             bool moveAlongRow,
             QVector<QPair<int, int>>& outPath) const;

    bool containsCell(const QVector<QPair<int, int>>& path, int r, int c) const;
};

#endif // CYCLESOLVER_H

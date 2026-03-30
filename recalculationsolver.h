#ifndef RECALCULATIONSOLVER_H
#define RECALCULATIONSOLVER_H

#pragma once

#include <QString>
#include <QVector>
#include <QPair>

#include "transportproblemstate.h"

struct RecalculationStep
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

struct RecalculationResult
{
    bool valid = false;
    QString message;

    int rValue = 0;
    int leavingRow = -1;
    int leavingCol = -1;

    QVector<QPair<int, int>> cyclePath;
    QVector<RecalculationStep> steps;
    QVector<QVector<QString>> newLoadMatrix;
};

class RecalculationSolver
{
public:
    RecalculationResult solve(const TransportProblemState& source,
                              const QVector<QVector<QString>>& currentLoadMatrix,
                              const QVector<QPair<int, int>>& cyclePath) const;

private:
    QVector<QVector<QString>> makeStringMatrix(int rows, int cols) const;
};

#endif // RECALCULATIONSOLVER_H
